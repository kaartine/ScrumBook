#require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require './project'

describe Project do
 	it "should not be in saved state when it is created" do
 		project = Project.new
 		project.saved?.should == false
 	end

	it "should not be possible to add new task without name" do
		project = Project.new
		task = Task.new("", "C", "open")
		lambda{project.addNewTaskToSprint(task)}.should raise_error
	end

	it "should be possible to add new task" do
		# add new task to first sprint that is 0
		project = Project.new
		task = Task.new("first", "C", "open")
		project.addNewTaskToSprint(task).should == true
		project.getActiveSprintsTasks.size.should == 1

		# there should not be any tasks in sprint 1
		project.sprint = 1
		project.getActiveSprintsTasks.should == nil
		task = Task.new("first", "C", "open")
		project.addNewTaskToSprint(task)
		project.getActiveSprintsTasks.size.should == 1
	end

	it "should not allow to add to tasks with same name to one sprint" do
		project = Project.new
		task = Task.new("first", "C", "open")
		project.addNewTaskToSprint(task).should == true
		project.getActiveSprintsTasks.size.should == 1

		task2 = Task.new("first", "CK", "closed")
		project.addNewTaskToSprint(task2).should == nil
		project.getActiveSprintsTasks.size.should == 1
	end

	it "should return tasks for active sprint" do
		project = Project.new
		project.getActiveSprintsTasks.should == nil
	end

	it "should trim name of the task" do
		task = Task.new("first  ", "C", "open")
		task.name = "  	updated   "
		task.name.should == "updated"
	end

	it "should not be possible to add duration that is not integer" do
		task = Task.new("first  ", "C", "open")
		task.addDuration(0, 10).should == 10
		task.addDuration(1, 0).should == 0
		lambda{task.addDuration(1, "")}.should raise_error
		lambda{task.addDuration(3, -10)}.should raise_error
		lambda{task.addDuration(4, "10")}.should raise_error
		lambda{task.addDuration(5, "jk")}.should raise_error

		task.duration.size.should == 2
	end
end
