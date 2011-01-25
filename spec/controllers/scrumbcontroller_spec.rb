require './controller/scrumbcontroller'

describe ScrumBController do

  before(:each) do
    @guiM = mock("GuiManager")
    @guiM.stub!(:refreshView)

 #   mock("Project")
  end

  after(:each) do
    Project.delete
  end

  it "should be possible to open project that is given as argument" do
    controller = ScrumBController.new(@guiM)

    ARGV[0] = "scrumbook.scb"

    @guiM.should_receive(:startMainLoop)
    @guiM.should_receive(:update_project)
    controller.startApp
  end

  it "should not be possible to open file that doesn't exists" do
    controller = ScrumBController.new(@guiM)

    ARGV[0] = "scrumbook_not_availabe.scb"

    @guiM.should_receive(:openInformationDialog).with("Error opening file", "File \"#{ARGV[0]}\" doesn't exist!")
    @guiM.should_receive(:startMainLoop)

    controller.startApp
  end

end