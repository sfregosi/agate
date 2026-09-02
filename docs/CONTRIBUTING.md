# Contributing to agate

Thanks for your interest in contributing to `agate`! This toolbox supports
processing and analysis of passive acoustic Seaglider data, and contributions
from the glider and passive acoustic monitoring community are welcome —
whether that's a bug fix, a new feature, better documentation, or just
flagging an issue.

## How to contribute

`agate` uses a fork-and-pull-request workflow. To contribute:

1. **Fork** the repository to your own GitHub account.
2. **Clone** your fork locally and create a new branch for your change:
   ```
   git checkout -b short-description
   ```
3. Make your changes, following the style and structure of the existing
   code where possible (see [Code style](#code-style) below).
4. **Commit** your changes with clear, descriptive commit messages.
5. **Push** your branch to your fork and open a **pull request** against
   the `main` branch of `sfregosi/agate`.
6. In the pull request description, briefly explain what changed and why.

Draft pull requests are welcome if you'd like early feedback on work that
isn't finished yet. We're happy to help get folks set up with this
process, so please reach out with any questions!

## Reporting issues

Found a bug? Please [open an issue](https://github.com/sfregosi/agate/issues/new)
using the **Bug report** template.

Have an idea for a new feature or an improvement to code or
documentation? Please [open an issue](https://github.com/sfregosi/agate/issues/new)
using the **Feature request** template.

## Code style

- Follow the existing code structure and naming conventions used
  throughout `agate` (e.g., function and variable naming, header/comment
  format).
- Include a function header comment describing purpose, inputs, and
  outputs for any new or modified function.
- Prefer clear, sequential logic over deeply nested conditionals where
  practical.
- Remove dead or commented-out code rather than leaving it in place —
  version history preserves it if it's ever needed again.

For the full coding conventions and templates for new functions and
scripts, see the [How to contribute](https://sfregosi.github.io/agate/contribute.html)
page on the documentation site.

## MATLAB compatibility

`agate` targets recent MATLAB releases (see the README for the currently
supported version) and has not been thoroughly tested for back
compatibility. If you encounter issues with a certain version, please
flag it as a bug. If your contribution requires a specific toolbox or a
newer MATLAB version, please note that in your pull request.

## Documentation

If your change affects how a function is used (new inputs, outputs, or
behavior), please update the associated help text/comments and, where
applicable, any relevant example workflow scripts.

## Testing

Before opening a pull request, please check that:

- Existing example workflows still run without error, where relevant to
  your change.
- Any new functionality has been tested against at least one real or
  representative dataset.

## Questions

If you're not sure whether a change fits the scope of `agate`, feel free
to open an issue to discuss it before starting work.