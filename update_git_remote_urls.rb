class GitUrlUpdator
  def initialize
    @dirs = Dir.glob('*/')
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
