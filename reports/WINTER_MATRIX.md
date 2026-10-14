# Frozen first-Winter matrix

## Content v4 loading audit

All thirty frozen v3 final saves load under 0.7.15-m7 / content v4, preserve every
gameplay field after restoring only their original content header for comparison,
pass invariants and round-trip under the current header. No time advances and
source files remain byte-identical. The raw audit is
`reports/winter-v3-v4-migration-audit.json`, SHA-256 `e054d6e5094e09d556c1c80e1233e7816536d242655bb1afe9d7e327b877898f`.
This verifies migration; the completed simulation matrix below remains v3 evidence.
A new v4 survival matrix is still required for that content revision.

## Frozen content v3 / schema 23

The current-content matrix passes **30/30** at clean, unchanged source
`fe118288c17efc56a252318d042c4bc1af1c2ac6` (0.7.7-m7). The same ten unsigned
seeds run on all three sites, from tick 1,800 through 239,400 in Standard mode.
All thirty retain eight residents, minimum health 100, zero zero-fullness and
starvation-grace-exceeded citizen-ticks, and no departure. Each checks 792 invariant
checkpoints (23,760 in total). The executable-work limit and retained queued orders
are active. The policy uses only public commands and real work/supplies.

The independent fail-closed audit verifies all thirty unique cases, unchanged
source identity, successful processes, clean engine/script logs, payload checksums,
exact final saves and round trips. There are 214 announced raid histories, five
recorded starts; ordinary policy may settle announced raids before arrival. This
is first-Winter scenario evidence and does not cover every danger or physical device.
The failed pre-run setup attempts (wrong import root, then LFS pointers) remain
separate logs and are not counted as simulation passes. No failed simulation was
retried to obtain this matrix.

Raw evidence is retained in ignored `reports/winter-release-v3-fe11828/` outside
the frozen checkout, which was archived after clean-source completion.
`tools/check_current_matrix.gd` additionally loads every final
save under 0.7.13-m7, checks all current invariants and round trips, and preserves
every full canonical hash and original input byte. This read-only 30/30 compatibility
audit advances no time; later pure optimizations have separate ordinary replay,
full-scan scheduler-oracle and actual snowy-save continuation evidence.

| File | SHA-256 |
| --- | --- |
| source.json | `466a458ba93db06187d5793e5048945d16033b34ad1407b3431757c9191fe604` |
| completion.json | `ee89a824c0b7f48e8cbfd9a1981f32de62eb0d709ad9a9ee8f57b889163a54f2` |
| audit.json | `0bcfec9a86b531f13a74334cc9afbbed22122eae2c85d15b40ec838fcde9a048` |
| ../winter-v3-current-save-audit.json | `4a40efd5971da1b427e2d6ba68e21ddb975b1466c113c7fc618f79578794ae80` |

| Site | Seed | Full v3 canonical SHA-256 | Final snapshot file SHA-256 |
| --- | ---: | --- | --- |
| meadow_reach | 0 | `d8562cd885b14c4656249753c397f4825b5cbab36f72a85e8783f673633b36bf` | `5c7ccb5c88c477a121b58a0e3c4db164f27656a055fcc552f4e62e64068e2492` |
| meadow_reach | 1 | `29d69602f77280fd217e71da07d0ef25a4dc81a4848013b634facd34ac37b4fc` | `f04719452344196b67af8bcda3a2d1e11e1b6e6101ffb5dc32a63bd2994c2935` |
| meadow_reach | 42 | `7acda72320cecef9fa5ad08daaa531e1635b67bfad98dc8ca48dc0becce7cb42` | `9dbb4f952c68ad49fef826cf8cecd14b0e6424bc6f5d8fdc227836942b1229f0` |
| meadow_reach | 73 | `4864a618b575ed431232029d8bbfef9990e757a9dae02a1cb1c4df88a59d668d` | `978d336936cdcaa2a067618e89858aed51331b76780753c4b3139c326da82a85` |
| meadow_reach | 4567 | `cb1b95587de9a64ba348376c62e3d330d08e969d2513d02bbba89e47063863e8` | `a678376eb6b077e552478fbbdc09d9b288251c5b7b5a33c39941d44503c3ad2a` |
| meadow_reach | 104729 | `24304e8208a91424972a0b7dfabe296e125e1c39b17bdb986305053df07e739a` | `e02da2e1bf020c9ba43825fd6c79cdf4a0a242eb3f5cf634124d8bdb4eb5f2dc` |
| meadow_reach | 1357911 | `3ede36d90ef3ddbcba996aebb1c1eba06cbc4b8fe30d5a51c4f56f6b0b240b86` | `12b21192e0384e2c5cde8cb8875c55f698802cf4bb87ca0f654480ff5a62b5d3` |
| meadow_reach | 2147483647 | `01edf6257dc249529ba4ec5c62fe121ec003fddcf1fdd3ab720f129c4dadf403` | `c32e82333bab3169b01badffcd54a58e3a5d765bcd1b490079896034f03be949` |
| meadow_reach | 3000000001 | `e1c3caeb610bf7ac8887124a8e639df29d6c9fc53893cc02594db3a72a9ccdb2` | `eaef78c9b992a596e8d9fd36d9bdfb77d0bed0db074c56454307313c4469beab` |
| meadow_reach | 4294967295 | `575e6e83d239f7e185070c3a119809dc7f241b5f2001d22ae9870d87f91b9f6d` | `55e0d3c49d317c4447988b7706a27b268bc5076c9182baa42c9ff3dbb6cfea20` |
| pine_shelf | 0 | `206468cda30fe62aed123a944b83a4dc50b89b6345a141364e50fa979b53b056` | `96c667ab28d612c59ef3129e6275b07d004580a72ba067c2f2d0eba2de8ae73f` |
| pine_shelf | 1 | `27cfb51c09721ff96f900b1352c9eeb4d018043dd52a0b9d37f155e71b034284` | `e397bd2ed6766819c111412c70764b9fd79ab731476f00ef4ffd29b3ce29a1a7` |
| pine_shelf | 42 | `1d9e4a32321d3f6b1bc02830a1d6ade09405237639c3a277dd62a2429ecbc44b` | `4f8e57714145c1ab49352f185f8d31b68c93094d02f38ac843c7cb52b0dee55e` |
| pine_shelf | 73 | `45e26686a180e9b86314e6b6aaefeb5f3de8af47a1c964e141be9f75cb765981` | `73dbcc53fd8c21f75f447ad526f890620b16ffaa051c0400c47b09741c9cb3c5` |
| pine_shelf | 4567 | `b215921919d0449884283a086f2aa8a6828aa3c5c0991df5f31434bc31e60f23` | `cf548a51493c1c2955e8a2aff3270c5e5c473b4bd937905d1b05b719c306af43` |
| pine_shelf | 104729 | `59302e3ee87839614e7b8f22fa9529d6c807f9f7f69c4d32a8a6d0e6b0477f5d` | `b5ecefceedb94f9b4a6c38bf6e6a92b84558dad131a9447be12a08e163904927` |
| pine_shelf | 1357911 | `c6519468199bbc3605fc7f7151e1bd7009e4c753989449325653700b7d741efd` | `ddfbdb02d055b669b4a8c31bbbdda903b3db9140a69956a16e0b00b02e9b4855` |
| pine_shelf | 2147483647 | `923f8cfac4404e91599ca88774a2c0cf1e7febec439373febd7e1b4c364e9b20` | `979df481db365f8fe574cb2c12924043f17207fd7eadc7dfd135466ffb949113` |
| pine_shelf | 3000000001 | `4aab60e4fb437d5e55777947e48880b6329e7a9c174d3ef038b034b26487f4cc` | `7c4d1f51def7d5c77035a61e2c2251832a8783f925b90d6e5b212d14456f1c81` |
| pine_shelf | 4294967295 | `e688901cdb95ee7936e5303baea4bd94403543c41b0cfb2cde5a036fa893c511` | `54af6ca62a8819a5bafbcdb6af6156ea165c919e89c8406990416b458dbb8d85` |
| reed_bend | 0 | `16953b0bc447fa17c91b76666f38aa7dd2c1f9b4b3731cd10f294377dc81a511` | `2078de4b29634a787d8b4126371d7a542f2c83688804da2d752944f4959f4484` |
| reed_bend | 1 | `0c4e561e725d176a01f44e81d1ec00710e46c371b5425207293327046492e980` | `9549ef5caf9c58432e7f1efbfd0158b730bedc791d348df299c7b0e70f302cf3` |
| reed_bend | 42 | `c2517d0488b61effe1f7001fb23783a2c57f13dbb9fffaaafd3e117f9270d176` | `4adfcf9ea33e030ef4a0d02967a9cccc7785f9a08e4cf7e23fa90f509cb96894` |
| reed_bend | 73 | `7e5556a1dc765894780183117abf0d269a2b3c269ba2949b045b8d69d7c00d35` | `944e889bfc75c15ac6c7379639f0ddd058148a9e5615b16ba4ad583bf9e9870c` |
| reed_bend | 4567 | `930c0b00e2680a68c3c6daa122e0d924696f64938418dc9c82425c2c8755d719` | `1ef5a7fedeed429fe02d971aa41a27d7023655b479d853bea7f4afea5233815f` |
| reed_bend | 104729 | `069f12082bc7c97730e41374966554ef4781d57a66ab01f26cf7ad3e6afa806a` | `5406cd2d1723e751063e35c463a44d55a327f1a91a4eb80ef090762cbaafeaf8` |
| reed_bend | 1357911 | `4e52027329dad240f03b0953a8b6c9f276a811ea668ff5adff409a1891d9a4d2` | `3db73cd41385083e7a69b686ee1ad7a8aefec25c1730f882ad614513366e2f35` |
| reed_bend | 2147483647 | `d4574f2b85fc1cb424d526ffe6df9980785d51beef4f3834b3301259136934cf` | `c4a3032c8be701bfa3b4c8117a0d71483cc8af10fc7253bb538e40d568829070` |
| reed_bend | 3000000001 | `44573af8761fa4b462aa14cbbf3dee90dac56289ae02aadc1fae242ddbe071b0` | `dcc7a12398bebf2d1dcab2bda4513b1e2fc393710b4911d403f715bbf11fafd4` |
| reed_bend | 4294967295 | `1353f453d6449fe2cc262313a6050917667e5b9530eb9abcab527af132b7d88d` | `051c7b8e5e81fb2922085069fd820357e83fa2fc90a754da793798004f67544c` |

## Earlier content v2 / schema 21

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
