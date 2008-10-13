require File.join(File.dirname(__FILE__), "spec_helper")
startup_merb

$:.push File.join(File.dirname(__FILE__), "fixtures")

describe Kernel, "#dependency" do
  
  before { reset_dependency('core_ext_dependency', :CoreExtDependency) }
  
  it "works even when the BootLoader has already finished" do
    dependency "core_ext_dependency"
    defined?(CoreExtDependency).should_not be_nil
  end
  
  it "takes :immediate => true to require a dependency immediately" do
    Merb::BootLoader::finished.delete("Merb::BootLoader::Dependencies")
    dependency "core_ext_dependency"
    defined?(CoreExtDependency).should be_nil
    dependency "core_ext_dependency", :immediate => true
    defined?(CoreExtDependency).should_not be_nil
    Merb::BootLoader::finished << "Merb::BootLoader::Dependencies"
  end
  
  it "returns a Gem::Dependency" do
    dep = dependency "core_ext_dependency", ">= 1.1.2"
    dep.name.should == "core_ext_dependency"
    dep.version_requirements.to_s.should == ">= 1.1.2"
  end
  
  it "adds a Gem::Dependency item to Merb::BootLoader::Dependencies.dependencies" do
    dep = dependency "core_ext_dependency", ">= 1.1.2"
    dep.name.should == "core_ext_dependency"
    dep.version_requirements.to_s.should == ">= 1.1.2"
    Merb::BootLoader::Dependencies.dependencies.should include(dep)
  end
  
  it "will replace any previously registered dependencies with the same name" do
    dep = dependency "core_ext_dependency", ">= 1.1.0"
    dep.version_requirements.to_s.should == ">= 1.1.0"
    dep = dependency "core_ext_dependency", ">= 1.1.2"
    dep.version_requirements.to_s.should == ">= 1.1.2"
    entries = Merb::BootLoader::Dependencies.dependencies.select { |d| d.name == dep.name }
    entries.first.version_requirements.to_s.should == ">= 1.1.2"
    entries.length.should == 1
  end
  
end

describe Kernel, "#load_dependency" do
  
  before { reset_dependency('core_ext_dependency', :CoreExtDependency) }
  
  it "requires a dependency immediately" do
    load_dependency "core_ext_dependency"
    defined?(CoreExtDependency).should_not be_nil
  end
  
  it "returns a Gem::Dependency" do
    dep = load_dependency "core_ext_dependency"
    dep.name.should == "core_ext_dependency"
    ["", ">= 0"].include?(dep.version_requirements.to_s.should)
  end
  
  it "adds a Gem::Dependency item to Merb::BootLoader::Dependencies.dependencies" do
    dep = load_dependency "core_ext_dependency"
    Merb::BootLoader::Dependencies.dependencies.should include(dep)
  end
  
end

describe Kernel, "#use_orm" do
  
  before do
    Kernel.stub!(:dependency)
    Merb.orm = :none # reset orm
  end
  
  it "should set Merb.orm" do
    Kernel.use_orm(:activerecord)
    Merb.orm.should == :activerecord
  end
  
  it "should add the the orm plugin as a dependency" do
    Kernel.should_receive(:dependency).with('merb_activerecord')
    Kernel.use_orm(:activerecord)
  end

end

describe Kernel, "#use_template_engine" do
  
  before do
    Kernel.stub!(:dependency)
    Merb.template_engine = :erb # reset orm
  end
  
  it "should set Merb.template_engine" do
    Kernel.use_template_engine(:haml)
    Merb.template_engine.should == :haml
  end
  
  it "should add merb-haml as a dependency for :haml" do
    Kernel.should_receive(:dependency).with('merb-haml')
    Kernel.use_template_engine(:haml)
  end
  
  it "should add merb-builder as a dependency for :builder" do
    Kernel.should_receive(:dependency).with('merb-builder')
    Kernel.use_template_engine(:builder)
  end
  
  it "should add no dependency for :erb" do
    Kernel.should_not_receive(:dependency)
    Kernel.use_template_engine(:erb)
  end
  
  it "should add other plugins as a dependency" do
    Kernel.should_receive(:dependency).with('merb_liquid')
    Kernel.use_template_engine(:liquid)
  end

end

describe Kernel, "#use_test" do
  
  before do
    Merb.test_framework = :rspec # reset orm
    Merb.stub!(:dependencies)
  end
  
  it "should set Merb.test_framework" do
    Kernel.use_test(:test_unit)
    Merb.test_framework.should == :test_unit
  end
  
  it "should not require test dependencies when not in 'test' env" do
    Merb.stub!(:env).and_return("development")
    Kernel.should_not_receive(:dependencies)
    Merb.use_test(:test_unit, 'hpricot', 'webrat')
  end
  
  it "should require test dependencies when in 'test' env" do
    Merb.stub!(:env).and_return("test")
    Kernel.should_receive(:dependencies).with(["hpricot", "webrat"])
    Merb.use_test(:test_unit, 'hpricot', 'webrat')
  end
  
end