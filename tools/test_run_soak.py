import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from run_soak import audit


class SoakAuditTests(unittest.TestCase):
    def setUp(self):
        self.directory=tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root=Path(self.directory.name)
        payload='{"tick":1860}'
        canonical=hashlib.sha256(payload.encode()).hexdigest()
        save=json.dumps({"payload":payload,"sha256":canonical}).encode()
        (self.root/'probe-final.brackenward').write_bytes(save)
        (self.root/'probe.log').write_text('Clean native exit\n')
        self.source={"commit":"frozen","seconds":3,"warmup":1,"sample_seconds":1,"speed":2,"snapshot_sha256":"input","harness_sha256":"harness"}
        self.result={"format":"brackenward-native-soak","version":1,"probe_pass":True,"completed":True,"release_gate_pass":False,"requested_seconds":3,"measured_wall_seconds":3.0,"warmup_seconds":1,"sample_seconds":1,"requested_speed":2,"final_speed":2,"snapshot_sha256":"input","harness_sha256":"harness","source_unchanged":True,"audio_drained":True,"roundtrip_verified":True,"final_canonical_hash":canonical,"final_snapshot_sha256":hashlib.sha256(save).hexdigest(),"initial_tick":1800,"final_tick":1860,"logical_ticks":60,"nominal_ticks":60,"logical_time_kept_up":True,"input_counts":{"residents":20},"population_kept":True,"fps_floor_proxy_pass":True,"fps_windows":3,"max_consecutive_low_fps_window_seconds":0.0,"engine_heap_proxy_within_20_mib":True,"engine_heap_growth_bytes":1024,"peak_sampled_engine_heap_growth_bytes":1024,"samples":[{"tick":1800+index*20,"phase":phase,"speed":0 if phase=="post_measurement_drain" else 2,"elapsed_seconds":index,"engine_heap_bytes":1000000+(1024 if index else 0),"invariants":[],"storage_error":"","saving_disabled":False,"counts":{"residents":20}} for index,phase in enumerate(['start','running','running','post_measurement_drain'])]}
        self.done={"exit_code":0,"source_unchanged":True}
        self.write()

    def write(self, result=None):
        (self.root/'source.json').write_text(json.dumps(self.source))
        path=self.root/'probe.json';path.write_text(json.dumps(self.result if result is None else result))
        self.done['report_sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
        (self.root/'completion.json').write_text(json.dumps(self.done))

    def test_complete_development_probe_does_not_become_thirty_minute_certificate(self):
        result=audit(self.root,'frozen')
        self.assertTrue(result['passed'])
        self.assertFalse(result['standard_30min_2x_case'])

    def test_engine_errors_with_zero_exit_and_ansi_are_rejected(self):
        for log in ['ERROR: failed\n','SCRIPT ERROR: failed\n','\x1b[31mERROR: failed\x1b[0m\n']:
            (self.root/'probe.log').write_text(log)
            self.assertFalse(audit(self.root,'frozen')['passed'])

    def test_false_success_fields_cannot_hide_incomplete_or_dropped_time(self):
        for field,value in [('completed',False),('measured_wall_seconds',2.0),('final_tick',1840),('source_unchanged',False),('final_speed',1),('release_gate_pass',True),('harness_sha256','changed'),('snapshot_sha256','changed')]:
            with self.subTest(field=field):
                result=copy.deepcopy(self.result);result[field]=value;self.write(result)
                self.assertFalse(audit(self.root,'frozen')['passed'])

    def test_population_memory_storage_and_invariant_failures_are_recomputed(self):
        for field,value in [('engine_heap_bytes',30*1024*1024),('engine_heap_bytes',None),('counts',{'residents':19}),('storage_error','failed'),('saving_disabled',True),('invariants',['bad']),('speed',1)]:
            with self.subTest(field=field,value=value):
                result=copy.deepcopy(self.result);result['samples'][1][field]=value;self.write(result)
                self.assertFalse(audit(self.root,'frozen')['passed'])

    def test_missing_or_changed_artifacts_are_rejected(self):
        self.assertFalse(audit(self.root,'other-source')['passed'])
        (self.root/'probe-final.brackenward').write_text('{}')
        self.assertFalse(audit(self.root,'frozen')['passed'])
        (self.root/'probe.json').unlink()
        self.assertFalse(audit(self.root,'frozen')['passed'])

    def test_completion_hash_and_exit_status_are_required(self):
        self.done['exit_code']=1;self.write()
        self.assertFalse(audit(self.root,'frozen')['passed'])
        self.done['exit_code']=0;self.done['error']='Timed out';self.write()
        self.assertFalse(audit(self.root,'frozen')['passed'])
        self.done['error']='';self.write()
        (self.root/'probe.json').write_text('{}')
        self.assertFalse(audit(self.root,'frozen')['passed'])


if __name__=='__main__': unittest.main()
