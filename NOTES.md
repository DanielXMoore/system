Notes
=====

2021-07-10
----------

Implemented lazy loading of AWS libraries. This begins the exploration of more
lazy loading for things like stylus, CoffeeScript and other compilers. This will
keep the system library small and ensure that people aren't forced to pay for
capabilities they don't use.

It should in theory be possible to lazy load without polluting the global
namespace but that is a serious scope creep for limited benefit. It may make
sense for things like CoffeeScript or stylus compilers but for AWS I pray that
we'll never want two versions at once.

2019-12-25
----------

Migrate `Model` into `system`. Explored using a single param `self` rather than
`I`, `self`. Pro: single param include makes more sense than the dual param for
stateless mixins like `Bindable`. Con: Having the state as a nested parameter of the
object is a little weird and makes calling in the normal case awkward. It also
makes re-hydrating from JSON or pojo more difficult than it needs to be.

Conclusion: keep the two param but expand `include` to handle single param
functions by special casing `mixin.length === 1` to skip the `I` param.

2019-10-26
----------

Testing on fs libs.

Removing dependencies on Model, using our Bindable. Avoiding implicit system
dependencies.

Organize deps?

```
system.UI
system.FS
system.DB

👍👍👍👍👍👍👍👍👍👍
```


2019-10-20
----------

🎶 _Ladytron - Destroy Everything You Touch_ 🎶

Goal: Consolidate FS into `lib/fs`

- [ ] Mount
- [ ] S3
- [ ] IndexedDB
- [ ] Package
- [ ] Add tests!
- [ ] Reduce / Clean up Deps
- [ ] Expose Mountable Root FS

Gathering from `zine` and `briefcase`

2019-10-18
----------

Consolidated styles into one file. 

Goal: get template and view previews working for system client in Prometheus.

For views adding require "../setup" creates a system client shim to work.
Think about templates... Got it with one weird plugin trick!

2019-09-21
----------

Updated Jadelet2 with the Firefox fix
Removed Jadelet v1 support
Pulled in Observable (non-rewrite v0.4.0-pre)

2019-09-11
----------

Moving in the new Jadelet parser and runtime. Plan to also move in othe package
dependencies and make this more of a comprenhensive runtime lib for ZineOS. The
plan is to also pull in Observable and Bindable, maybe even merge with system
client. We can always reconsider splitting out the UI stuff later, but having a
fuller core lib makes sense, especially if it doesn't get too large.

---

Wrapping simple promise returning handlers around the modal should make it easy
to prompt.
