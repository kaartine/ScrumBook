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


require './lib/helpfunctions.rb'

class Project

  attr_accessor :name, :sprint, :sprintlength, :members, :tasks, :fileName

  attr_reader :sprintHours, :task_id, :not_saved, :backlog

  private_class_method :new

  @@project = nil

  def Project.loadModel(project)
    logger "Project.loadModel(project) #{project.inspect}", 4
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

    @backlog = Array.new
    @tasks = Hash.new
    @sprint = 0
    @sprintHours = Hash.new
    @task_id = 1
    @@project = nil
  end

  def update(project)
    @fileName = project.fileName
    @sprintlength = project.sprintlength
    @not_saved = project.not_saved

    @tasks = project.tasks
    @backlog = project.backlog
    @sprint = project.sprint
    @sprintHours = project.sprintHours
    @task_id = project.task_id
  end

  def saved?
    !@not_saved
  end

  def set_to_saved
    @not_saved = false
  end

  def modified
    @not_saved = true
  end

  def getActiveSprintsTasks
    @tasks[@sprint]
  end

  def add_new_task_to_backlog(newTask)
    if newTask.name.size == 0
      raise ArgumentError, "Name is not set"
    end

    @backlog = Array.new if @backlog.nil?

    newTask.project = self
    logger "no parent", 4
    @backlog.push(newTask)

    newTask.task_id = @task_id
    @task_id += 1
    @not_saved = true
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

    newTask.project = self

    if parentTask_id.nil?
      logger "no parent", 4
      @tasks[@sprint].push(newTask)
    elsif id = @tasks[@sprint].index(parentTask_id)
      logger "parent in first level", 4
      @tasks[@sprint][id].addSubTask(newTask)
      parentFound = true
    else
      logger "parent is in lower levels", 4
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

    newTask.task_id = @task_id
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
    deleted = delete_backlog_task(task_id)
    deleted = delete_sprint_task(task_id) if deleted.nil?

    deleted
  end

  def delete_backlog_task(task_id)
    logger "delete_backlog_task id: #{task_id}", 4
    return if @backlog.nil?
    @not_saved = true

    task = find_backlog_task(task_id)
    if !task.nil?
      return @backlog.delete(task_id)
    end

    nil
  end

  def delete_sprint_task(task_id)
    logger "delete_sprint_task id: #{task_id}", 4
    return if @tasks[@sprint].nil?
    @not_saved = true

    task = findTask(task_id)
    if !task.nil? && !task.parent.nil?
      t = task.parent
      return t.tasks.delete(task_id)
    elsif !task.nil?
      return @tasks[@sprint].delete(task_id)
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
    find_task_with(task_id, @tasks[@sprint])
  end

  def find_backlog_task(task_id)
    find_task_with(task_id, @backlog)
  end

  private

  def initialize
    clear
  end

  def find_task_with(task_id, from_array)
    found = nil
    from_array.each do |t|
      found = t.find(task_id)
      break if !found.nil?
    end
    found
  end

end


class Task
  attr_accessor :committer, :status, :name, :project, :task_id, :estimate, :milestone, :comment, :targetted_sprint
  attr_reader :duration, :tasks

  def initialize( name, committer, status )
    @name = name.strip
    @committer = committer.strip
    @status = status.strip
    @comment = ''
    @targetted_sprint = 0
    @duration = Array.new
    @duration.push("")
    @project = nil
    @tasks = Array.new
    @task_id = -1
    @parent = nil
  end

  def name=(n)
    @project.modified unless @project.nil?
    @name = n.strip
  end

  def committer=(c)
    @project.modified unless @project.nil?
    @committer = c.strip
  end

  def status=(s)
    @project.modified unless @project.nil?
    @status = s.strip
  end

  def estimate=(s)
    @project.modified unless @project.nil?
    @estimate = s.strip
  end

  def milestone=(s)
    @project.modified unless @project.nil?
    @milestone = s.strip
  end

  def comment=(s)
    @project.modified unless @project.nil?
    @comment = s
  end

  def targetted_sprint=(value)
    if Integer(value) && value >= 0
      @project.modified unless @project.nil?
      @targetted_sprint = value
    elsif value.size > 0
      raise ArgumentError, "Duration should be positive integer or zero"
    end
  end

  def addDuration(i, value)
    if Integer(value) && value >= 0
      @project.modified unless @project.nil?
      @duration[i] = value
    elsif value.size > 0
      raise ArgumentError, "Duration should be positive integer or zero"
    end
  end

  def addSubTask(newTask)
    raise ArgumentError, "Parent task is same as new task!" if newTask.task_id == self.task_id

    @project.modified unless @project.nil?
    newTask.parent = self.task_id
    @tasks.push(newTask)
  end

  def ==(id)
    self.task_id == id
  end

  def find(task_id)
    logger "find: #{task_id} current #{@task_id}", 4
    found = nil
    if @task_id == task_id
      logger "found", 4
      return self
    else
      logger @tasks.inspect, 4
      @tasks.each do |t|
        found = t.find(task_id)
        break if found
      end
    end
    logger "found: #{found}", 4
    found
  end

  def findAndPush(parentTask_id, newTask)
    found = nil
    if @task_id == parentTask_id
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

  def parent=(id)
    @parent = id
  end

  def parent
    @project.findTask(@parent) unless @project.nil?
  end
end
