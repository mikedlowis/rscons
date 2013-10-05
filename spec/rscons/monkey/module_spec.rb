describe "Module#short_name" do
  it "returns the inner name of the module" do
    Rscons::Environment.short_name.should == "Environment"
    Rscons::Object.short_name.should == "Object"
  end
end
