---
name: research-repo
description: Research GitHub repositories, issues, pull requests, users, or anything else GitHub hosts. Use when the user asks about a GitHub repo or wants to look something up on GitHub.
---

# Research GitHub with `gh`

Use `gh` to research GitHub. Never use web search or web
fetch for it. `gh` gives authenticated, structured access
to every GitHub resource.

## Extracting the repo identifier

From a full URL like `https://github.com/owner/repo`,
take `owner/repo`. From a bare repo name, run
`gh search repos <name> --limit 5` and confirm the match
with the user if more than one fits.

## Commands by category

Run independent commands in parallel. Replace `owner/repo`
with the actual identifier.

### Repo overview

```sh
gh repo view owner/repo
gh repo view owner/repo --json name,description,stargazerCount,forkCount,primaryLanguage,licenseInfo,latestRelease,createdAt,updatedAt,isArchived,homepageUrl,defaultBranchRef
```

### Activity and health

```sh
gh api repos/owner/repo/contributors --jq '.[].login' | head -20
gh api repos/owner/repo/commits?per_page=5 --jq '.[].commit.message'
gh issue list -R owner/repo --limit 10
gh pr list -R owner/repo --limit 10
gh release list -R owner/repo --limit 5
```

### Deeper investigation

```sh
gh api repos/owner/repo/languages
gh api repos/owner/repo/topics --jq '.names'
gh api repos/owner/repo/community/profile
gh issue list -R owner/repo --label bug --limit 10
gh api repos/owner/repo/stats/commit_activity
gh api repos/owner/repo/stats/participation
```

### Reading files from a repo

```sh
gh api repos/owner/repo/readme --jq '.content' | base64 -d
gh api repos/owner/repo/contents/<path>
```

### Searching across GitHub

```sh
gh search repos <query> --limit 10
gh search issues <query> --limit 10
gh search prs <query> --limit 10
gh search code <query> --limit 10
```

## Presenting results

Condense the data into a short, factual summary. Call out
warning signs: archived, no license, unusual activity
level, high issue count, stale releases. Answer the
question the user asked. Don't dump every field for a
narrow question.
