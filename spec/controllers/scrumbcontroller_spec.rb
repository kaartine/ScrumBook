require './scrumbcontroller'

describe ScrumBController do

  before(:each) do
    @guiM = mock("GuiManager")
    @guiM.stub!(:refreshView)

    @project = mock("Project")
  end

  it "should be possible to open project that is given as argument" do
    controller = ScrumBController.new(@project, @guiM)

    ARGV[0] = "scrumbook.scb"

    @guiM.should_receive(:startMainLoop)
    @project.should_receive(:update)
    @project.should_receive(:fileName=)
    controller.startApp
  end

  it "should not be possible to open file that doesn't exists" do
    controller = ScrumBController.new(@project, @guiM)

    ARGV[0] = "scrumbook_not_availabe.scb"

    @guiM.should_receive(:openInformationDialog).with("Error opening file", "File \"#{ARGV[0]}\" doesn't exist!")
    @project.should_not_receive(:fileName=)
    @project.should_not_receive(:update)
    @guiM.should_receive(:startMainLoop)

    controller.startApp
  end

end