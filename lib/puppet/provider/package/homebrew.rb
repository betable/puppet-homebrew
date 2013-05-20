require 'etc'
require 'puppet/provider/package'

Puppet::Type.type(:package).provide(:brew, :parent => Puppet::Provider::Package) do
  desc "Package management using HomeBrew on OS X"

  confine  :operatingsystem => :darwin

  has_feature :versionable

  def self.execute_options
    pw = Etc.getpwuid(Process.euid)
    {
      :custom_environment => {
        "HOME" => ENV["HOME"] || pw.dir,
        "USER" => ENV["SUDO_USER"] || ENV["USER"] || pw.name,
      },
      :gid => (ENV["SUDO_GID"] || pw.gid).to_i,
      :uid => (ENV["SUDO_UID"] || pw.uid).to_i,
    }
  end

  if respond_to? :has_command
    has_command :brew, "/usr/local/bin/brew" do
      environment Puppet::Type::Package::ProviderBrew.execute_options[:custom_environment]
    end
  else
    commands :brew => "/usr/local/bin/brew"
  end

  # Install packages, known as formulas, using brew.
  def install
    should = @resource[:ensure]

    package_name = @resource[:name]
    case should
    when true, false, Symbol
      # pass
    else
      package_name += "-#{should}"
    end

    output = execute([command(:brew), :install, package_name], self.class.execute_options)

    # Fail hard if there is no formula available.
    if output =~ /Error: No available formula/
      raise Puppet::ExecutionFailure, "Could not find package #{@resource[:name]}"
    end
  end

  def uninstall
    execute([command(:brew), :uninstall, @resource[:name]], self.class.execute_options)
  end

  def update
    self.install
  end

  def query
    self.class.package_list(:justme => resource[:name])
  end

  def latest
    hash = self.class.package_list(:justme => resource[:name])
    hash[:ensure]
  end

  def self.package_list(options={})
    brew_list_command = [command(:brew), "list", "--versions"]

    if name = options[:justme]
      brew_list_command << name
    end

    begin
      list = execute(brew_list_command, execute_options).
        lines.
        map {|line| name_version_split(line) }
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not list packages: #{detail}"
    end

    if options[:justme]
      return list.shift
    else
      return list
    end
  end

  def self.name_version_split(line)
    if line =~ (/^(\S+)\s+(.+)/)
      name = $1
      version = $2
      {
        :name     => name,
        :ensure   => version,
        :provider => :brew
      }
    else
      Puppet.warning "Could not match #{line}"
      nil
    end
  end

  def self.instances(justme = false)
    package_list.collect { |hash| new(hash) }
  end
end
