---
name: research-repo
description: Research GitHub repositories, issues, PRs, users, or any GitHub-hosted information. TRIGGER when the user asks about a GitHub repo, wants to investigate a project, compare repos, or look up anything on GitHub.
---

# Research GitHub using the `gh` CLI

Always use the `gh` CLI to research GitHub. Never use web
search or web fetch to access GitHub -- `gh` provides
authenticated, structured access to all GitHub data.

## Extracting the repo identifier

If the user provides a full URL like
`https://github.com/owner/repo`, extract the `owner/repo`
portion. If the user provides just a repo name without an
owner, use `gh search repos <name> --limit 5` to find
candidates and confirm with the user if ambiguous.

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

Synthesize gathered data into a concise, factual summary.
Highlight anything notable (archived, no license, unusually
active/inactive, high issue count, stale releases).
Structure around what the user asked -- do not dump all
available data if they asked a specific question.
