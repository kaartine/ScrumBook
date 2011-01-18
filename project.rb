# Copyright (C) 2011 by Jukka Kaartinen

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require './helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :not_saved, :fileName

  attr_reader :sprintHours, :task_id

  private_class_method :new

  @@project = nil

  def initialize
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
    @task_id = 1
  end

  def Project.loadModel(project)
    @@project = project
    @@project
  end

  def Project.create
    @@project = new unless @@project
    @@project
  end

  def Project.delete
    @@project = nil
  end

  def clear
    @fileName = ""
    @sprintlength = 10
    @not_saved = true

    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
  end

  def update(project)
    @fileName = project.fileName
    @sprintlength = project.sprintlength
    @not_saved = project.not_saved

    @tasks = project.tasks
    @sprint = project.sprint
    @sprintHours = project.sprintHours
    @task_id = project.task_id
  end

  def saved?
    !@not_saved
  end

  def getActiveSprintsTasks
    @tasks[@sprint]
  end

  def addNewTaskToSprint(newTask, parentTask_id=nil)
    if newTask.name.size == 0
      raise ArgumentError, "Name is not set"
    end

    if parentTask_id
      Integer(parentTask_id)
    end


    logger "before: " + @tasks.inspect, 4
    if !@tasks.has_key?(@sprint)
      @tasks[@sprint] = Array.new
    end

    if parentTask_id.nil?
      logger "no parent", 4
      @tasks[@sprint].push(newTask)
    elsif id = @tasks[@sprint].index(parentTask_id)
      logger "parent in first level"
      @tasks[@sprint][id].addSubTask(newTask)
      parentFound = true
    else
      logger "parent is in lowet levels"
      @tasks[@sprint].each do |t|
        if t.findAndPush(parentTask_id, newTask)
          parentFound = true
          break
        end
      end
    end

    if parentTask_id && parentFound == false
      logger "BUG: parent was not found: " + parentTask_id
      exit
    end

    newTask.id = @task_id
    @task_id += 1
    @not_saved = true
  end

  def getSprintHours(sprint=nil)
    index = @sprint
    if !sprint.nil?
      index = sprint
    end
    if @sprintHours[index].nil?
      return 0
    end
    @sprintHours[index]
  end

  def setSprintHours( hours, sprint=nil )
    index = @sprint
    if !sprint.nil?
      index = sprint
    end
    @not_saved = true
    @sprintHours[index] = hours
  end

  def deleteTask(task_id)
    return if @tasks[@sprint].nil?
    @not_saved = true

    task = findTask(task_id)
    logger task.inspect
    if !task.nil?
      return @tasks[@sprint].delete(task_id)
    elsif !task.nil? && !task.parent.nil?
      t = task.parent
      return t.delete(task_id)
    end
    nil
  end

  def moveTaskUp(task_id)
    task = findTask(task_id)
    tasks = nil?
    if task.parent.nil?
      tasks = @tasks[@sprint]
    else
      tasks = task.parent.tasks
    end

    id1 = tasks.index(task_id)
    if id1 == 0 || tasks.size <= 1
      return
    end
    @not_saved = true
    tasks[id1-1], tasks[id1] = tasks[id1], tasks[id1-1]
  end

  def moveTaskDown(task_id)
    task = findTask(task_id)
    tasks = nil?
    if task.parent.nil?
      tasks = @tasks[@sprint]
    else
      tasks = task.parent.tasks
    end

    id1 = tasks.index(task_id)
    if id1 == tasks.size-1 || tasks.size <= 1
      return
    end
    @not_saved = true
    tasks[id1], tasks[id1+1] = tasks[id1+1], tasks[id1]
  end

  def findTask(task_id)
    found = nil
    @tasks[@sprint].each do |t|
      found = t.find(task_id)
      break if found
    end
    found
  end
end


class Task
  attr_accessor :committer, :status, :name, :project, :id, :parent
  attr_reader :duration, :tasks

  def initialize( name, committer, status, project = nil )
    @name = name.strip
    @committer = committer.strip
    @status = status.strip
    @duration = Array.new
    @duration.push("")
    @project = project
    @tasks = Array.new
    @id = -1
    @parent = nil
  end

  def name=(n)
    @project.not_saved = true unless @project.nil?
    @name = n.strip
  end

  def committer=(c)
    @project.not_saved = true unless @project.nil?
    logger "update commiter: " + @project.not_saved.to_s
    @committer = c.strip
  end

  def status=(s)
    @project.not_saved = true unless @project.nil?
    @status = s.strip
  end

  def addDuration(i, value)
    if Integer(value) && value >= 0
      @project.not_saved = true unless @project.nil?
      @duration[i] = value
    elsif value.size > 0
      raise ArgumentError, "Duration should be positive integer or zero"
    end
  end

  def addSubTask(newTask)
    raise ArgumentError, "Parent task same as new task!" if newTask === self

    @project.not_saved = true unless @project.nil?
    newTask.parent = self
    @tasks.push(newTask)
  end

  def ==(id)
    self.id == id
  end

  def find(task_id)
    logger "find: #{task_id} current #{@id}"
    found = nil
    if @id == task_id
      logger "found"
      return self
    else
      found = nil
      @tasks.each do |t|
        found = t.find(task_id)
        break if found
      end
    end
    found
  end

  def findAndPush(parentTask_id, newTask)
    found = nil
    if @id == parentTask_id
      return addSubTask(newTask)
    else
      found = false
      @tasks.each do |t|
        found = t.findAndPush(parentTask_id, newTask)
        break if found
      end
    end
    found
  end

end
