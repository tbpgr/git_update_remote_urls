# Git | remote リポジトリのURLを一括で変更するRubyスクリプト

## 概要
remote リポジトリのURLを一括で変更するRubyスクリプト。

利用例としては、GitLabのドメイン（IPで利用している場合はIP）を変更した場合に
GitLabから clone したローカル環境の大量の remote リポジトリの設定を旧ドメインから
新ドメインに変更することです。

## 前提
* 旧リポジトリドメインを ***old_repo*** , 新リポジトリドメインを ***new_repo*** とします。
* remote リポジトリはすべて *origin* として設定しているものとします
* URLに ***old*** を含まない remote リポジトリは処理対象外とします
* 同一ディレクトリ直下に各リポジトリが clone されているものとします

~~~bash
$ tree
┣ repo1
┣ repo2
┣ : 略
┣ repoY
┗ repoZ
~~~

* リポジトリは下記が存在するものとします

※otherは remote_url に ***old_repo*** を含まないものとします。

~~~bash
$ tree
┣ hoge
┣ hige
┣ hage
┗ other
~~~

## プログラム

~~~ruby
class Dir
  def self.dirs(pattern)
    Dir.glob(pattern).select { |e|File.directory?(e) }
  end
end

class GitUrlUpdator
  def initialize
    @dirs = Dir.dirs("*")
  end

  def each
    @dirs.each do |dir|
      Dir.chdir(dir)
      yield(dir, self)
      Dir.chdir('../')
    end
  end

  def target_repo?(name)
    `git remote -v`.include?(name)
  end

  def rename(old_repo, new_repo)
    old_url = read_old_url
    new_url = old_url.gsub(old_repo, new_repo)
    `git remote rm origin`
    `git remote add origin #{new_url}`
    puts "Complete rename [#{old_url}] to [#{new_url}]"
  end

  private

  def read_old_url
    repo_url_src = `git remote -v`.split("\n").first
    repo_url_src =~ /
      (?<remote_name>origin)
      \t
      (?<url>.+)
      \s
      (?<fetch_or_pull>\(.+\))
      /x
    $~[:url]
  end
end

old_repo = 'old_repo'
new_repo = 'new_repo'
git_url_updator = GitUrlUpdator.new
git_url_updator.each do |dir, git_url_updator|
  next unless git_url_updator.target_repo?(old_repo)
  git_url_updator.rename(old_repo, new_repo)
end
~~~

## 変更前後の確認

~~~bash
# 変更前の remote の設定を確認
$ cd hoge
$ git remote -v
origin  git@old_repo:some_group/hoge.git (fetch)
origin  git@old_repo:some_group/hoge.git (push)

$ ../
# remote の設定を変更
$ ruby update_git_remote_urls.rb
Complete rename [git@old_repo:some_group/hoge.git] to [git@new_repo/hoge.git]
Complete rename [git@old_repo:some_group/hige.git] to [git@new_repo/hige.git]
Complete rename [git@old_repo:some_group/hage.git] to [git@new_repo/hage.git]

# 変更後の remote の設定を確認
$ cd hoge
$ git remote -v
origin  git@new_repo:some_group/hoge.git (fetch)
origin  git@new_repo:some_group/hoge.git (push)
~~~
