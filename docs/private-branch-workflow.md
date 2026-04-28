# Private Branch Workflow

This repository is designed to support one local checkout with:

- `origin`: the public broker repository
- `private`: your private broker repository

The public branch stays safe to publish. The private branch carries secrets and
environment-specific broker material.

## Recommended Branches

- `main`: public-safe branch
- `private/main`: private-only branch

## Add The Private Remote

```bash
git remote add private <PRIVATE_REMOTE_URL>
```

## Push Public Changes

Use this path only for shareable broker changes.

```bash
git checkout main
git push origin main
```

## Push Private Changes

Use this path for real password files, private ACL entries, or environment-only
broker changes.

```bash
git checkout private/main
git push private private/main
```

## Promote A Private Change To Public

If part of a private change becomes safe to share:

1. switch to `main`
2. reimplement or cherry-pick only the safe subset
3. scrub secrets
4. push `main` to `origin`

Never push private-only commits directly to `origin`.
