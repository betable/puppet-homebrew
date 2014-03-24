Facter.add(:has_compiler) do
  confine :operatingsystem => :darwin
  setcode do
    File.exists?('/Library/Developer')
  end
end
