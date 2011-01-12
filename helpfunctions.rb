$debug_level = 3

def logger text, level = 3
  if level <= $debug_level
    print text + "\n"
  end
end

def numOfColumns
  # task name, commiter, status, sprints
  1 + 1 + 1 + @project.sprintlength
end


def selectDay(index)
  index%5
end