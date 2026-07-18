using System;
using System.IO;
using LibGit2Sharp;

// GitHubPusher —— 把本地文件夹的文件提交并推送到 GitHub
// 用法: dotnet run -- <本地文件夹> <仓库URL> <GitHub用户名> <PAT令牌> [提交信息]
class GitHubPusher
{
    static void Main(string[] args)
    {
        if (args.Length < 4)
        {
            Console.WriteLine("用法: GitHubPusher <本地文件夹> <仓库URL> <用户名> <PAT令牌> [提交信息]");
            Console.WriteLine("示例: GitHubPusher C:\\MyFiles https://github.com/lucy/myrepo.git lucy ghp_xxxx \"backup files\"");
            return;
        }

        string localPath = args[0];
        string remoteUrl = args[1];
        string username  = args[2];
        string token     = args[3];
        string message   = args.Length > 4 ? args[4] : $"Auto push {DateTime.Now:yyyy-MM-dd HH:mm}";

        // 1. 如果文件夹还不是 git 仓库，先初始化
        string repoPath = Repository.Discover(localPath) ?? Repository.Init(localPath);
        using var repo = new Repository(repoPath);

        // 2. 确保远程 origin 存在并指向目标仓库
        var origin = repo.Network.Remotes["origin"];
        if (origin == null)
            repo.Network.Remotes.Add("origin", remoteUrl);
        else if (origin.Url != remoteUrl)
            repo.Network.Remotes.Update("origin", r => r.Url = remoteUrl);

        // 3. 暂存所有改动（新增、修改、删除）
        Commands.Stage(repo, "*");

        var status = repo.RetrieveStatus();
        if (!status.IsDirty)
        {
            Console.WriteLine("没有需要提交的改动。");
            return;
        }

        // 4. 提交
        var author = new Signature(username, $"{username}@users.noreply.github.com", DateTimeOffset.Now);
        repo.Commit(message, author, author);
        Console.WriteLine($"已提交: {message}");

        // 5. 推送（使用 PAT 认证）
        var pushOptions = new PushOptions
        {
            CredentialsProvider = (_url, _user, _types) =>
                new UsernamePasswordCredentials { Username = username, Password = token }
        };

        string branchName = repo.Head.FriendlyName; // 通常是 main 或 master
        repo.Network.Push(repo.Branches[branchName], pushOptions);
        Console.WriteLine($"已推送到 {remoteUrl} ({branchName} 分支)");
    }
}
