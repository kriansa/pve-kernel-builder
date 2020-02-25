# Where does each of the patches here apply?

For more info, see file `bin/build-kernel`.

* Patches on folder `kernel/` are meant to be copied along with the ones present
  on `pve-kernel` codebase, at the same path (`patches/kernel`).

* Those present at `builder/` folder are meant to be directly applied
  (using `git apply`) to the `pve-kernel` root codebase before the build
  process begin.
