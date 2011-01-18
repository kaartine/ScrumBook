#require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require './project'

describe Project do
  after(:each) do
    Project.delete
  end

  it "should not be in saved state when it is created" do
    project = Project.create
    project.saved?.should == false
  end

  it "should not be possible to add new task without name" do
    project = Project.create
    task = Task.new("", "C", "open")
    lambda{project.addNewTaskToSprint(task)}.should raise_error
  end

  it "should be possible to add new task" do
    # add new task to first sprint that is 0
    project = Project.create
    task = Task.new("first", "C", "open")
    project.addNewTaskToSprint(task).should == true
    project.getActiveSprintsTasks.size.should == 1
    task = Task.new("second", "C", "open")
    project.addNewTaskToSprint(task).should == true
    project.getActiveSprintsTasks.size.should == 2

    tasks = project.getActiveSprintsTasks
    tasks[0].id.should == 1
    tasks[1].id.should == 2

    # there should not be any tasks in sprint 1
    project.sprint = 1
    project.getActiveSprintsTasks.should == nil
    task = Task.new("first", "C", "open")
    project.addNewTaskToSprint(task)
    project.getActiveSprintsTasks.size.should == 1

    tasks = project.getActiveSprintsTasks
    tasks[0].id.should == 3
  end

  it "should return tasks for active sprint" do
    project = Project.create
    project.getActiveSprintsTasks.should == nil
  end

  it "should trim name of the task" do
    task = Task.new("first  ", "C", "open")
    task.name = "    updated   "
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
    project = Project.create
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
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.addNewTaskToSprint(third)
    project.getActiveSprintsTasks.size.should == 3
    project.deleteTask(second.id).should == second
    project.deleteTask(second.id).should == nil
    project.deleteTask(100).should == nil
    project.getActiveSprintsTasks.size.should == 2
    project.sprint = 1
    project.deleteTask(first.id).should == nil
    project.sprint = 0
    project.deleteTask(first.id).should == first
  end

  it "should be possible to add sub task" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.addNewTaskToSprint(third)
    first2 = Task.new("find me", "C", "open")
    first3 = Task.new("first", "C", "open")
    second2 = Task.new("second", "C", "closed")
    project.addNewTaskToSprint(first2,first.id)
    project.addNewTaskToSprint(first3,first.id)
    project.addNewTaskToSprint(second2,second.id)
    first3 = Task.new("find also me", "C", "open")
    project.addNewTaskToSprint(first3,second.id)

    # should not be possible to add self to it self
    lambda{ project.addNewTaskToSprint(first2,first2.id) }.should raise_error

    project.getActiveSprintsTasks.size.should == 3

    project.findTask(4).name.should == "find me"
    project.findTask(7).name.should == "find also me"
    project.findTask(7).parent.should === second
  end

  it "should be possible to move task up" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.getActiveSprintsTasks[0].name.should == "first"
    project.getActiveSprintsTasks[1].name.should == "second"
    project.moveTaskUp(1)
    project.getActiveSprintsTasks[0].name.should == "first"
    project.getActiveSprintsTasks[1].name.should == "second"
    project.moveTaskUp(2)
    project.getActiveSprintsTasks[1].name.should == "first"
    project.getActiveSprintsTasks[0].name.should == "second"
  end

  it "should be possible to move task down" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.getActiveSprintsTasks[0].name.should == "first"
    project.getActiveSprintsTasks[1].name.should == "second"
    project.moveTaskDown(2)
    project.getActiveSprintsTasks[0].name.should == "first"
    project.getActiveSprintsTasks[1].name.should == "second"
    project.moveTaskDown(1)
    project.getActiveSprintsTasks[1].name.should == "first"
    project.getActiveSprintsTasks[0].name.should == "second"
  end


  it "should be possible to move sub task up" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.addNewTaskToSprint(third)
    first2 = Task.new("find me", "C", "open")
    first3 = Task.new("first", "C", "open")
    second2 = Task.new("second", "C", "closed")
    project.addNewTaskToSprint(first2,first.id)
    project.addNewTaskToSprint(first3,first.id)
    project.addNewTaskToSprint(second2,second.id)

    project.findTask(1).tasks[0].name.should == "find me"
    project.moveTaskUp(5)
    project.findTask(1).tasks[0].name.should == "first"
  end

  it "should be possible to move sub task down" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.addNewTaskToSprint(third)
    first2 = Task.new("find me", "C", "open")
    first3 = Task.new("first", "C", "open")
    second2 = Task.new("second", "C", "closed")
    project.addNewTaskToSprint(first2,first.id)
    project.addNewTaskToSprint(first3,first.id)
    project.addNewTaskToSprint(second2,second.id)

    project.findTask(1).tasks[0].name.should == "find me"
    project.moveTaskDown(4)
    project.findTask(1).tasks[0].name.should == "first"
  end

  it "should be possible to delete sub task" do
    project = Project.create
    first = Task.new("first", "C", "open")
    second = Task.new("second", "C", "closed")
    third = Task.new("third", "C", "closed")
    project.addNewTaskToSprint(first)
    project.addNewTaskToSprint(second)
    project.addNewTaskToSprint(third)
    first2 = Task.new("find me", "C", "open")
    first3 = Task.new("first", "C", "open")
    second2 = Task.new("second", "C", "closed")
    project.addNewTaskToSprint(first2,first.id)
    project.addNewTaskToSprint(first3,first.id)
    project.addNewTaskToSprint(second2,second.id)


    puts project.inspect + "\n"
    project.deleteTask(5)
    puts project.inspect + "\n"

     project.findTask(5).should == nil

  end

end
