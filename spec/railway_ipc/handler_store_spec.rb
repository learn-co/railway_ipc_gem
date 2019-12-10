RSpec.describe RailwayIpc::HandlerStore do
  it "registeres handlers" do
    store = RailwayIpc::HandlerStore.new
    store.register(message: "A Message", handler: "A Handler")
    manifest = store.get("A Message")
    expect(manifest).to be_a(RailwayIpc::HandlerManifest)
    expect(manifest.message).to eq("A Message")
    expect(manifest.handler).to eq("A Handler")
  end
  it "returns all handleable messages" do
    store = RailwayIpc::HandlerStore.new
    store.register(message: "A Message", handler: "A Handler")
    store.register(message: "Another Message", handler: "Another Handler")
    expect(store.registered).to eq(["A Message", "Another Message"])
  end
end
