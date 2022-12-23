# template-stacks

This repository is a template of a monorepo for declaratively managing infrastructure and configuration.

## Updating from the template

To pull updates from this template to your repository instance, add this template repository as a remote to your
repository instance:

```bash
git remote add template git@github.com:cncsc/template-stacks.git
```

Then, fetch the most recent changes:

```bash
git fetch --all
```

Then, merge the changes from this template to your repository instance:

```bash
git merge template/main --allow-unrelated-histories
```
