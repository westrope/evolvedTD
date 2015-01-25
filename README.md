# Getting Started

Welcome to [EvolveTD][wiki], an evolutionary Tower Defense game!

The following sections walk you through cloning, branching, commiting,
pushing, and merging code changes using [Git](http://git-scm.com/).

## Cloning

First, we get download a copy of the repository to our machine (note
the use of [SSH][] for authentication):

	git clone git@github.com:tsoule88/evolvedTD.git
	cd evolveTD

Now we run `git status`. Notice that it will say we are "on branch
`master`", this branch is the default. Its first commit is the first
commit in the repo. Commits are discrete sets of changes to the files
tracked in the repo, and what Git does is record these in a tree,
effectively keeping track of the entire history of changes to a
codebase.

## Branching

Since the `master` branch is special, we want to keep it stable, which
means that it should only be changed after a code review. So in order
to record and share changes that we wish to eventually merge into
`master`, we commit them to a different branch and share that. Once
the branch's changes have been reviewed by our peers (on GitHub, in a
[Pull Request][pr]), the entire branch is merged back into `master`.

You should start with a "personal" branch, perhaps using your GitHub
alias, so that you have a base point for *your* commits:

    git checkout -b andschwa

This command did two things: it created the branch `andschwa` *and* it
checked the branch out, meaning that our `HEAD` reference (a pointer
or marker to the checked out commit) now points to the tip of the new
branch. When we commit, it is added to the commit tree as a child of
the commit that our `HEAD` reference marks. With each commit we add to
this branch, the `andschwa` branch reference (and `HEAD`) is moved to
the new commit, but `master` (and other branches) are not, so the
history has diverged. This is a good thing, because the differences
can be compared, discussed, reviewed, and merged back in easily via
[Pull Request][pr].

The two things the above command did are equivalent to this:

    git branch andschwa
    git checkout andschwa

> Git has lots of documentation; use `git help subcommand` to read it,
> e.g. `git help checkout`.

Checking out a reference, i.e. a branch name or a commit hash, will
update the local files such that they match their state at the given
reference. If `git status` indicates you have modified files (use `git
diff` to see the differences), then you'll either want to commit them,
or if you're not quite ready to do so, you can [stash][] them away for
later using `git stash`.

> Use `git status -sb` to quickly see your current branch and changes

# Commiting

Go ahead and make some changes to any tracked file and save it. Git
status should now list the file as modified under "Changes not staged
for commit". This means Git is aware we've changed the file, but no
more. If we want to record these changes, we need to *stage* them to
the index (i.e. staging area), which is Git-speak for marking which
changes we want in the next commit (it doesn't have to include every
change).

> See the [online documentation][stage] for more!

Unstaged changes can be seen using `git diff`, and staged changes can
be seen using `git diff --cached` (`--staged` is an alias). The `diff`
command also accepts arbitrary ranges of references as well as paths
to particular files, but by default it shows the changes between our
working tree and the staging area, hence why staged changes are
excluded without the flag.

Perhaps you fixed a typo of mine and so have modified `README.md`, to
add the all the changes in the file to the stage, do this:

    git add README.md

Git status should now list the modifications under "Changes to be
committed".

> Use `git add --patch` to interactively stage changes

To finish the commit and thus record the changes to the repository, we
need to [write a commit message][commit]. The first line should be a
one-line summary of the changes in the commit; for longer messages,
leave a blank line, and then add details. Commit messages should be
imperative: "Fix bug", not "Fixed bug" or "Fixes bug", e.g.:

    git commit -m "Fix typo in Getting Started"

Executing `git commit` without a message will open the program defined
in our `$EDITOR` environment variable, where a longer commit message
can be written.

# Pushing

## TODO

Briefly explain git remotes and then `git push`

# Merging

## TODO

Explain the GitHub Flow / Pull Request review process and merging

[wiki]: http://course.cs.uidaho.edu/wiki404/index.php/Main_Page
[ssh]: https://help.github.com/articles/generating-ssh-keys/
[pr]: https://help.github.com/articles/using-pull-requests/
[stash]: http://git-scm.com/book/en/v1/Git-Tools-Stashing
[stage]: http://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
[commit]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html

# Dependencies

## Processing

- [Download](https://processing.org/download/)
- [Tutorials](https://processing.org/tutorials/)
- [Reference](https://processing.org/reference/)
- [GitHub](https://github.com/processing)
- [Wiki](https://github.com/processing/processing/wiki)

If you wish to use Processing from the command line (or with
`processing-mode` in Emacs etc.), install the binaries through the
menu "Tools" -> "Install 'processing-java'".

## Box2D for Processing

- [Source](https://github.com/shiffman/Box2D-for-Processing)
- [Releases](https://github.com/shiffman/Box2D-for-Processing/releases)
- [Distribution](https://github.com/shiffman/Box2D-for-Processing/releases/download/2.0/box2d_processing.zip)

Can be installed through the Processing IDE menu "Sketch" -> "Import
Library" -> "Add Library" -> "Box2D for Processing". Can also be
[installed manually][lib].

[lib]: https://github.com/processing/processing/wiki/How-to-Install-a-Contributed-Library
