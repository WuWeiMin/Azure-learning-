using System;
using System.IO;
using LibGit2Sharp;

// GitHubPusher —— 把本地文件夹的文件提交并推送到 GitHub
// 用法: dotnet run -- <本地文件夹> <仓库URL> <用户名> <PAT令牌> [提交信息] [指定文件]
// 不填"指定文件"则推送文件夹里所有改动
class GitHubPusher
{
    static void Main(string[] args)
    {
        if (args.Length < 4)
        {
            Console.WriteLine("用法: GitHubPusher <本地文件夹> <仓库URL> <用户名> <PAT令牌> [提交信息] [指定文件]");
            return;
        }

        string localPath = args[0];
        string remoteUrl = args[1];
        string username  = args[2];
        string token     = args[3];
        string message   = args.Length > 4 ? args[4] : $"Auto push {DateTime.Now:yyyy-MM-dd HH:mm}";
        string fileToPush = args.Length > 5 ? args[5] : "*";   // 默认推送所有改动

        // 1. 如果文件夹还不是 git 仓库，先初始化
        string repoPath = Repository.Discover(localPath) ?? Repository.Init(localPath);
        using var repo = new Repository(repoPath);

        // 2. 确保远程 origin 存在并指向目标仓库
        var origin = repo.Network.Remotes["origin"];
        if (origin == null)
            repo.Network.Remotes.Add("origin", remoteUrl);
        else if (origin.Url != remoteUrl)
            repo.Network.Remotes.Update("origin", r => r.Url = remoteUrl);

        // 3. 暂存改动（指定文件或全部）
        Commands.Stage(repo, fileToPush);

        // 4. 有改动就提交，没改动也继续往下推送
        var status = repo.RetrieveStatus();
        if (status.IsDirty)
        {
            var author = new Signature(username, $"{username}@users.noreply.github.com", DateTimeOffset.Now);
            repo.Commit(message, author, author);
            Console.WriteLine($"已提交: {message}");
        }
        else
        {
            Console.WriteLine("没有新改动，直接推送已有提交。");
        }

        // 5. 把本地分支和远程 origin 关联起来（解决 upstream 报错）
        var branch = repo.Head;
        repo.Branches.Update(branch, b =>
        {
            b.Remote = "origin";
            b.UpstreamBranch = branch.CanonicalName;
        });

        // 6. 推送（使用 PAT 认证）
        var pushOptions = new PushOptions
        {
            CredentialsProvider = (_url, _user, _types) =>
                new UsernamePasswordCredentials { Username = username, Password = token }
        };

        repo.Network.Push(branch, pushOptions);
        Console.WriteLine($"已推送到 {remoteUrl} ({branch.FriendlyName} 分支)");
    }
}
