# Released simulation compatibility

M1 sources preserve commit 25db464. M2 sources preserve commit 978b6d5, including rectangle resource orders. These modules replay older durable journals under their original rules before a pure forward migration creates a current snapshot. Never balance or refactor the frozen simulator alongside current gameplay changes. Each matching catalog remains immutable.
