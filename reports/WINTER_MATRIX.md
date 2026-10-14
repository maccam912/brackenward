# Frozen first-Winter matrix

14 October 2026: 30/30 Standard first-Winter runs pass against the clean, unchanged
source commit `88ee5e83861b8bd639a2237deca0fb9ae838e2a6`. Ten unsigned seeds
run once on each of Meadow Reach, Pine Shelf and Reed Bend, from tick 1,800 to
239,400 (33 complete game days). Every run retains eight living residents, minimum
health 100, zero zero-fullness or starvation-grace-exceeded citizen-ticks, no forced
departure and 792 invariant checkpoints. The policy uses public commands and real
work/supplies, with no state grants. This passes the specified 90% survival target.

The reports retain 214 announced raid incident histories; 5 reached their recorded
arrival/start before resolution. Payment/ordinary policy actions may settle announced
raids. This is not an assertion that every danger type naturally occurred. Forced
fire, flood, wildlife, combat and incident fixtures remain separate suites.

`tools/winter_sweep.py --audit` independently checked all thirty unique site/seed
combinations, source identity, successful process exits, script/engine-error-free
logs, exact final snapshot digests and saved-world round trips. The initial wrapper
used harness SHA `5d01b72c440bcf8074e5fdaf859af70cebc497b8b19fe7f1b1cdb03d70a0c600`;
the fail-closed audit used SHA `05e2419413a0c16e2ea22c2bacf039911ddd9d20e422e337b717e1a631bea215`.
No retry or source edit was used to turn a failed simulation into a pass. The managed
validation checkout was archived only after completion and a clean-source check.

Raw reports, initial/final snapshots, command traces and logs remain in ignored
`reports/winter-release-88ee5e8/`, outside that checkout. Evidence digests:

| File | SHA-256 |
| --- | --- |
| source.json | `7812db39e9194a099694edd8a4ed5f8350ba63e7384bbca9cf1e3c1e042885da` |
| completion.json | `a25d9fca7777be38fa3d21e5393ed774de39c54c07bbb9e77c5f4b4744041c0f` |
| audit.json | `4c0b6d3190ca71ab867017d265693cb9b3aff565089115e355cd0e31844d653e` |
| ../winter-current-upgrade-matrix.json | `0da292db800fde0015f60244b76c8bf1923567ad2427e5687bcf85e59e87f92a` |

`tools/check_cosmetic_upgrade.gd` then loaded all thirty frozen schema-21 final
snapshots with current schema-22 code, without advancing time or rewriting source
files. Removing only the declared appearance fields/header addition recreates each
exact original gameplay hash. All thirty current snapshots also round-trip, and all
original input bytes remain unchanged. This verifies migration preservation, not
a new thirty-run simulation under later code. Audio and accessibility are presentation
changes; current replay goldens are independently retained. Physical hardware, human
comprehension, release signing and the M7 stress/art gates are separate.

| Site | Seed | Frozen gameplay canonical SHA-256 | Frozen snapshot file SHA-256 |
| --- | ---: | --- | --- |
| meadow_reach | 0 | `ac3a1b5bdc4e9f75dcc27ba870c627e19fe623b11b415ea8946bedc05bed9ec2` | `f235bf1e8f0bf1a47a9fcee81124165d0c53baf9a5ad2077f0bdd42290f40f28` |
| meadow_reach | 1 | `49e957e269b930e8df6150d9f5ddeca42fac7d8259e140e47d9e885194991b0a` | `001153d341eaa2112b57f68133199d26a931dc04b6ea9738165c29af66610625` |
| meadow_reach | 42 | `1b0302100262807a4725177ca0d1327853b00bfa2aa73228df922a02fe05aa21` | `52d0df5e12721b227d48c74cbc8d46577f1e60b62d0a1ae92ad1e5fc6392fa09` |
| meadow_reach | 73 | `b6cdc85bc327b61bf7374a8176fd2e254b1206ce8307aca7f79da28736c0e399` | `266bb86bc4f1f9693e33897e97388aefc1be19dbfba49fde7691ae9d0266c9e8` |
| meadow_reach | 4567 | `46dee61749b6a3e2f3a22fdba0ba663c5e68cda132827be498b5bab9026e4536` | `2a3d04939cf4507c9f546ec6589b672d6254fd1fbc51acb8734dbc3a24349f36` |
| meadow_reach | 104729 | `e6d5113edbaf73ae6503f98477f598ce2722411fc5a95c444a38ea0a4f2cfb1f` | `8b73236e61f2e28a824477f9f6381538ef22c71260d2052aa6cc24c8f05cb770` |
| meadow_reach | 1357911 | `b36789c889b6dfa301e920766d76502b29dab8c41ca6c116737cde2249b61b50` | `2ae024e8ea01b4f93815fcc16c5d46fcf9914b85a52f852a5113ad926e8179c5` |
| meadow_reach | 2147483647 | `678e6744838fa49fef95ad59f32829e5273f9106ed074934ef5e8e2f555677b3` | `cb889bda6e94b6adca6d5f5203acb920520e22d138a7477e2b14d861f30af674` |
| meadow_reach | 3000000001 | `8b7944ef2a7d9077e3e11449ff282afeb67866b35cb067a572cad714e36af8ed` | `da0b2e9435a9448d91d6a3e55076600f07ef6d9424846af7c7c751c65e3334ac` |
| meadow_reach | 4294967295 | `f444cb66e1baa1f50b179a75fdee3a8f18c8777cb024459dd7cd317193884aa3` | `0f957a84e833b4399c3b575d4990136ce7565c9be8d41cc4b117c7fdc1b588ae` |
| pine_shelf | 0 | `8994c09d2c25969cae5874a58075dcecd6287f9f6c1823e0430870fa71e8a088` | `46cbcb5385d3ecf9cadba976c3eb97a2a1962720b95f809489a378d743e7be0d` |
| pine_shelf | 1 | `f73238c874d5773cade1e994a0e9e684204afb56975cb01b93bdfe86133ac883` | `afec6cbd82f989afdda9b0df21f6f52d9dda63b9e8a5241fe0767febb73e20fd` |
| pine_shelf | 42 | `d031b205f3924879f26514c5365be9732262b9eb8535c1f56c651e714d7d3143` | `1826f72c18b3d6fa9daba9f623650bf466385afa185a421f0b668c545c84fc01` |
| pine_shelf | 73 | `0a646b409958516a56a650ec86e2f4d84cdc31f3ecabf8f0e8c08b09c666fbb7` | `6e0ba35ccd0d6f3b8d0678ae773e0ce6493f7b0c70c8b95455e40ecb281d8d5d` |
| pine_shelf | 4567 | `c1bd7d54818c202b47c740ad33d6601c1c2607aabae6312f613191171551007d` | `bd9e09f30dc067ab155e08628a257436526b257c36c105371e7271d15309ffb2` |
| pine_shelf | 104729 | `ad44d500866b6c1449a30f0aa687dd55f5f2a04153931310dc81e86624e86a86` | `3d63b5313dbf9f607b2b92b478db4e8b374adf9edc5a98efaca933ff46218fc3` |
| pine_shelf | 1357911 | `96adf113163aa642184aae746eb356f7797233f086fca5d60fad5335a4e120d9` | `cd95fcfe8ee2ffc232ca9ee4340f0237e221e2aa40904ddd9e41fed3ede7c820` |
| pine_shelf | 2147483647 | `bab40397beaceca17dfd78e015a87714478695d73734509470a4fda669773991` | `5f1b3f4e351f12b0dc131abf46a019edff47d409990dbe5f6fc5395e89cecc3d` |
| pine_shelf | 3000000001 | `85ec9b33f785e99b53ce40224d6efeae4f541d88bdd1e73c887206156287e368` | `3f4bbb28d743e836b3a28ad44cfe66d64bafd15ecfc54f540d8696de8fd32291` |
| pine_shelf | 4294967295 | `6d213fe95d7a81a6d281d61efb359d1559459c40b6a07ef3db6488282f33039b` | `24d79872ead850c7cbfd9ec5b8b07b0090c38475d711908cab61175c2bbf77fe` |
| reed_bend | 0 | `00389904bfb25a9e1895893ca1d8602a078f4dd46d9ec4255e049c0889ecd971` | `542b8539bad68977428c2ff0fdbcdc1a928d31232ade91b0b0c5248b0a140030` |
| reed_bend | 1 | `793670add6ce06ec5706edfa182e8eae9387d17c3d6422abfba51df6a260514f` | `48b736dc572b5e54cba474520b9a77386f871a60eeef95e9525f49bfcc43e305` |
| reed_bend | 42 | `55353596d681297f4ac5895e4c19ff8b0a4761b945aeb12256f41f047800d213` | `a2d071445c7ff2869a56ba5b48247e9060287fdfe64228d4be44195aa5360498` |
| reed_bend | 73 | `6d1f740b6b718057ac9146719f8e1c21db518baf0a0a67134b04147e7e18b995` | `fd574029ce4b347aaa39f548bbd0efc33f3cb12e73950c65285f488674d96bf1` |
| reed_bend | 4567 | `9fffc958e4fd3d512a27d220a2b757fe913d16d28862437c10f6f53d7f7f6591` | `14a2450db6ab3073fe9c4073d6edde8c245c469d133e7615de49c86a53f26724` |
| reed_bend | 104729 | `17d9faf4a5188aee1d3fdc3c28a3922d5262e7b5a95381ba05bb16ba4d17f6db` | `6b22dd493f344f29e308d0d88ca47206419d619fb1bd37c5a131d85876a1d300` |
| reed_bend | 1357911 | `4298044bcde122be8779ac2ca82d937187b459cbb792381fe9941c1ab08462ec` | `e1d8fb526440ebbe6c4043acea47237ec6c3035539d80056a0656a39b76f3996` |
| reed_bend | 2147483647 | `645e988f5de7f19252dc99e911398759d09122ec1056a7fb75a18ea241c6b90f` | `dbccecc0abd691bf5becfebf929913747bd50c04a51671d1e8f4f9abeb6a4716` |
| reed_bend | 3000000001 | `94fe53235d6ede686ce54337efda37dfa345138a0c5c86bf27fbe891998f7f52` | `6c4a113d7bc6ccfa0b7ca08126ddf2a6d1876507c98ecdf96736aa6d8144f559` |
| reed_bend | 4294967295 | `a059876be69b87e95faf1f14ff39f9fef32c682911d076206d8fdf30a7642e7e` | `b105c30207e47ccdd447498358dd4def49965bc6815e622880289e9de306ad3f` |
