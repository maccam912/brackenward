#!/usr/bin/env python3
"""Run/audit one native source soak from a clean frozen checkout; retain every outcome."""
import argparse
import hashlib
import json
import math
import os
import signal
from pathlib import Path
import re
import subprocess
import sys
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def valid_frame_heap_trace(value):
    if not isinstance(value,dict) or value.get('format')!='brackenward-native-frame-heap' or type(value.get('version')) is not int or value['version']!=1 or value.get('event_limit')!=32:
        return False
    for name in ['valid_frame_samples','unavailable_frame_samples','highwater_changes']:
        if type(value.get(name)) is not int or value[name]<0: return False
    frames,changes=value['valid_frame_samples'],value['highwater_changes']
    events=value.get('events');context=value.get('peak_context')
    if not isinstance(events,list) or len(events)!=min(changes,32) or changes>frames or not isinstance(context,dict): return False
    baseline,maximum,growth=(value.get(name) for name in ['baseline_bytes','max_bytes','peak_growth_bytes'])
    if baseline is not None and (type(baseline) is not int or baseline<=0): return False
    if maximum is None: return baseline is None and frames==0 and changes==0 and growth is None and not context
    if type(maximum) is not int or maximum<=0: return False
    if baseline is None:
        if growth is not None or frames==0 or changes==0: return False
    elif maximum<baseline or type(growth) is not int or growth!=maximum-baseline: return False
    previous=baseline or 0
    for event in events:
        if not isinstance(event,dict) or set(event)!= {'heap_bytes','context'} or type(event['heap_bytes']) is not int or event['heap_bytes']<=previous or not isinstance(event['context'],dict): return False
        previous=event['heap_bytes']
    if events: return maximum==events[-1]['heap_bytes'] and context==events[-1]['context']
    return maximum==baseline and not context


def audit(reports, commit):
    try:
        source = json.loads((reports / "source.json").read_text())
        done = json.loads((reports / "completion.json").read_text())
        path = reports / "probe.json"
        result = json.loads(path.read_text())
        save = reports / "probe-final.brackenward"
        envelope = json.loads(save.read_text())
        exact = hashlib.sha256(envelope["payload"].encode()).hexdigest()
        log = (reports / "probe.log").read_text()
        clean_log = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", log)
        clean = not re.search(r"(?m)^(SCRIPT ERROR:|ERROR:|FAIL )", clean_log)
        samples = result["samples"]
        heaps = [row["engine_heap_bytes"] for row in samples if row["engine_heap_bytes"] is not None]
        memory = bool(heaps) and len(heaps)==len(samples) and all(type(value) is int and value>0 for value in heaps) and max(heaps)-heaps[0] <= 20*1024*1024
        nominal = math.floor(result["measured_wall_seconds"]*source["speed"]*10)
        logical = result["final_tick"]-result["initial_tick"]
        ticks_match = result["nominal_ticks"] == nominal and result["logical_ticks"] == logical and logical >= nominal-2
        sampled = bool(samples) and all(not row["invariants"] and not row["storage_error"] and not row["saving_disabled"] and row["counts"]["residents"] >= result["input_counts"]["residents"] and row["speed"]==(0 if row["phase"]=="post_measurement_drain" else source["speed"]) for row in samples)
        ordered = (bool(samples) and samples[0]["phase"]=="start" and samples[-1]["phase"]=="post_measurement_drain"
            and samples[0]["tick"]==result["initial_tick"] and samples[-1]["tick"]==result["final_tick"]
            and all(a["elapsed_seconds"] <= b["elapsed_seconds"] and a["tick"] <= b["tick"] for a,b in zip(samples,samples[1:])))
        enough = len(samples) >= max(2,source["seconds"]//source["sample_seconds"])
        trace_valid = 'frame_heap_trace' not in result or valid_frame_heap_trace(result['frame_heap_trace'])
        passed = (result["format"]=="brackenward-native-soak" and result["version"]==1 and clean and done["exit_code"] == 0 and done["source_unchanged"] is True and not done.get("error","") and source["commit"] == commit
            and done["report_sha256"] == sha(path) and result["probe_pass"] is True and result["completed"] is True
            and result["release_gate_pass"] is False and result["requested_seconds"] == source["seconds"]
            and result["measured_wall_seconds"] >= source["seconds"] and result["warmup_seconds"] == source["warmup"]
            and result["sample_seconds"] == source["sample_seconds"] and result["requested_speed"] == result["final_speed"] == source["speed"]
            and result["snapshot_sha256"] == source["snapshot_sha256"] and result["harness_sha256"] == source["harness_sha256"]
            and result["source_unchanged"] is True and result["audio_drained"] is True and result["roundtrip_verified"] is True
            and exact == envelope["sha256"] == result["final_canonical_hash"] and sha(save) == result["final_snapshot_sha256"]
            and result["logical_time_kept_up"] is True and ticks_match and sampled and ordered and enough and memory
            and result["population_kept"] is True and result["engine_heap_proxy_within_20_mib"] is True
            and result["fps_floor_proxy_pass"] is True and result["fps_windows"]>0 and result["max_consecutive_low_fps_window_seconds"]<=30
            and result["peak_sampled_engine_heap_growth_bytes"] == max(heaps)-heaps[0]
            and result["engine_heap_growth_bytes"] == heaps[-1]-heaps[0] and trace_valid)
        return {"passed":bool(passed),"source_commit":commit,"standard_30min_2x_case":source["seconds"]==1800 and source["speed"]==2 and source["warmup"]>=60,"scope":"Native source probe and sampled engine-heap proxy; physical release gates remain open","measured_wall_seconds":result["measured_wall_seconds"],"logical_ticks":logical,"peak_sampled_engine_heap_growth_bytes":max(heaps)-heaps[0] if heaps else None,"final_residents":samples[-1]["counts"]["residents"],"final_snapshot_sha256":sha(save),"audit_tool_sha256":sha(Path(__file__))}
    except (OSError,ValueError,KeyError,TypeError,IndexError) as error:
        return {"passed":False,"error":str(error),"audit_tool_sha256":sha(Path(__file__))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",type=Path,required=True)
    parser.add_argument("--snapshot",type=Path)
    parser.add_argument("--report-dir",type=Path,required=True)
    parser.add_argument("--seconds",type=int,default=1800)
    parser.add_argument("--warmup",type=int,default=60)
    parser.add_argument("--sample-seconds",type=int,default=60)
    parser.add_argument("--speed",type=int,choices=[1,2,4],default=2)
    parser.add_argument("--audit",action="store_true")
    args=parser.parse_args()
    source,reports=args.source.resolve(),args.report_dir.resolve()
    commit=subprocess.check_output(["git","rev-parse","HEAD"],cwd=source,text=True).strip()
    if subprocess.check_output(["git","status","--porcelain"],cwd=source): parser.error("The source checkout must be clean and stay frozen")
    if not 3<=args.seconds<=1800 or not 1<=args.warmup<=120 or not 1<=args.sample_seconds<=300: parser.error("Invalid bounded soak duration")
    if args.audit:
        result=audit(reports,commit)
        (reports/"audit.json").write_text(json.dumps(result,indent=2)+"\n")
        print(json.dumps(result));raise SystemExit(0 if result["passed"] else 1)
    if args.snapshot is None or not args.snapshot.is_file(): parser.error("Choose an existing snapshot")
    snapshot=args.snapshot.resolve()
    reports.mkdir(parents=True,exist_ok=True)
    if any(reports.iterdir()): parser.error("Use a new empty report directory to preserve earlier evidence")
    harness=source/"tools/soak_foreground.gd"
    provenance={"commit":commit,"source":str(source),"snapshot":str(snapshot),"snapshot_sha256":sha(snapshot),"harness_sha256":sha(harness),"seconds":args.seconds,"warmup":args.warmup,"sample_seconds":args.sample_seconds,"speed":args.speed,"started_unix":time.time(),"launcher_sha256":sha(Path(__file__))}
    (reports/"source.json").write_text(json.dumps(provenance,indent=2)+"\n")
    timeout=args.seconds+args.warmup+180
    code=None
    error=""
    with (reports/"probe.log").open("w") as log:
        try:
            process=subprocess.Popen([sys.executable,str(source/"tools/checked_godot.py"),"--timeout",str(timeout),"--","--audio-driver","Dummy","--resolution","960x600","--script","tools/soak_foreground.gd","--","--snapshot",str(snapshot),"--seconds",str(args.seconds),"--warmup",str(args.warmup),"--sample-seconds",str(args.sample_seconds),"--speed",str(args.speed),"--report",str(reports/"probe.json")],cwd=source,stdout=log,stderr=subprocess.STDOUT,start_new_session=os.name=="posix")
            code=process.wait(timeout=timeout+30)
        except subprocess.TimeoutExpired:
            error="Bounded native run timed out; partial evidence retained"
            if os.name=="posix":
                try: os.killpg(process.pid,signal.SIGTERM)
                except ProcessLookupError: pass
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    try: os.killpg(process.pid,signal.SIGKILL)
                    except ProcessLookupError: pass
                    process.wait()
            else:
                subprocess.run(["taskkill","/PID",str(process.pid),"/T","/F"],stdout=log,stderr=subprocess.STDOUT,check=False)
                process.wait(timeout=10)
            code=process.returncode
    unchanged=(commit==subprocess.check_output(["git","rev-parse","HEAD"],cwd=source,text=True).strip() and not subprocess.check_output(["git","status","--porcelain"],cwd=source) and sha(snapshot)==provenance["snapshot_sha256"] and sha(harness)==provenance["harness_sha256"])
    path=reports/"probe.json"
    (reports/"completion.json").write_text(json.dumps({"exit_code":code,"error":error,"source_unchanged":unchanged,"report_sha256":sha(path) if path.exists() else None,"finished_unix":time.time()},indent=2)+"\n")
    result=audit(reports,commit)
    (reports/"audit.json").write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result))
    raise SystemExit(0 if result["passed"] else 1)


if __name__=="__main__": main()
