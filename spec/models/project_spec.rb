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

	it "should be possible to set and get hours for many different sprints" do
	  project = Project.new
	  project.getSprintHours.should == 0
	  project.setSprintHours(100)
	  project.sprint = 1
	  project.setSprintHours(150)
	  project.setSprintHours(200, 2)

    project.sprint = 0
	  project.getSprintHours.should == 100
	  project.sprint = 1
	  project.getSprintHours.should == 150
	  project.getSprintHours(0).should == 100
	  project.getSprintHours.should == 150
	  project.getSprintHours(2).should == 200
	end

	it "should be possible to delete tasks from project" do
	  project = Project.new
	  project.addNewTaskToSprint(Task.new("first", "C", "open"))
	  project.addNewTaskToSprint(Task.new("second", "C", "closed"))
	  project.addNewTaskToSprint(Task.new("third", "C", "closed"))
	  project.getActiveSprintsTasks.size.should == 3
    project.deleteTask("second").should == "second"
    project.deleteTask("second").should == nil
    project.deleteTask("seconds").should == nil
    project.getActiveSprintsTasks.size.should == 2
    project.sprint = 1
    project.deleteTask("first").should == nil
    project.sprint = 0
    project.deleteTask("first").should == "first"
  end

end
