RSpec.describe RailwayIpc do
  it "has a version number" do
    expect(RailwayIpc::VERSION).not_to be nil
  end

  it "starts the consumers running" do
    rake_task = double("rake_task")
    expect(Rake::Task).to receive(:[]).with("sneakers:run").and_return(rake_task)
    expect(rake_task).to receive(:invoke)
    RailwayIpc.start
  end
end
