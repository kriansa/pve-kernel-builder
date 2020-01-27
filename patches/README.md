# Where does each of the patches here apply?

* Patches on folder `kernel/` are meant to be copied along with the ones present
  on `pve-kernel` codebase, at the same path (`patches/kernel`).

* Those present at the root (`patches/`) are meant to be directly applied
  (using `git apply`) to the `pve-kernel` root codebase before the build
  process begin.
