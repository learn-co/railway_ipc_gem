require "bundler/setup"
require "railway_ipc"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f }

logger = Logger.new(STDOUT)
logger.level = :fatal

RailwayIpc.configure(
  logger: logger
)

class ISpec
  def self.before(&block)
    call_block(block)
  end
  def self.describe(statement, &block)
    puts "  #{statement}" if ENV["INTEGRATION"]
    call_block(block)
  end

  def self.context(statement, &block)
    puts "    #{statement}"
    call_block(block)
  end

  def self.it(statement, &block)
    puts "      #{statement}"
    if call_block(block)
      puts "        \e[32msuccess\e[0m"
    else
      puts "        \e[31mfailure\e[0m"
    end
  end

  def self.call_block(block)
    block.call if ENV["INTEGRATION"]
  end
end
