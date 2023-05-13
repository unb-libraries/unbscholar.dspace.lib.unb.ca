# UNB Libraries Development workflow
We operate a development workflow where two primary branches, 'dev' and 'prod', are utilized.

* Dev Branch: The 'dev' branch, short for "development," is commonly used as the main branch for ongoing development work. It serves as a central hub for integrating various feature branches, bug fixes, and other code changes from individual developers or development teams. Developers typically create feature branches off 'dev', work on their respective features, and then merge them back into 'dev' when they are ready for integration and testing.
* Prod Branch: The 'prod' branch, short for "production," is typically used to represent the stable and production-ready state of your application. This branch contains the code that is deployed to your live or production environment. It should ideally be a more stable and tested version of your application compared to the 'dev' branch.

## Promoting Changes from dev to prod
For simplicity sake, we use a rebase model to promote changes from dev to prod. The typical workflow for managing code changes and promoting them from 'dev' to 'prod' involves the following steps:

1. **Ensure you are on the 'dev' branch**: Before starting the rebase process, make sure you are currently on the 'dev' branch. You can switch to the 'dev' branch using the following command:

```
git checkout dev
```

2. **Fetch the latest changes**: Fetch the latest changes from the remote repository to ensure you have the most up-to-date version of the 'dev' branch. Use the following command:

```
git fetch origin dev
```

3. **Rebase 'prod' onto 'dev'**: Perform the rebase operation to incorporate the changes from 'dev' into 'prod'. Execute the following command:

```
git rebase dev prod
```

   This command applies the commits from the 'prod' branch onto the latest commit of the 'dev' branch, essentially replaying the 'prod' branch on top of 'dev'.

4. **Resolve any conflicts**: During the rebase process, if there are any conflicting changes between 'dev' and 'prod', Git will pause the rebase and prompt you to resolve the conflicts manually. Open the affected files, resolve the conflicts by editing the conflicting sections, and save the changes.

5. **Continue the rebase**: After resolving the conflicts, mark them as resolved using the following command:

```
git add .
```

   Then continue the rebase process by executing the following command:

```
git rebase --continue
```

   If there are additional conflicts, repeat steps 4 and 5 until the rebase is successfully completed.

6. **Push the rebased 'prod' branch**: Once the rebase is finished and there are no more conflicts, push the rebased 'prod' branch to the remote repository using the following command:

```
git push origin prod
```

This step ensures that the remote 'prod' branch is updated with the rebased changes.

By following these steps, you can rebase the 'prod' branch onto the latest commit of the 'dev' branch, effectively incorporating the changes from 'dev' into 'prod'.
