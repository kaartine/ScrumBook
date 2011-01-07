$debug_level = 3

def logger text, level = 3
	if level <= $debug_level
		print text + "\n"
	end
end