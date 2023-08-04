module DynamicMigrations
  class Generator
    module FixIndentation
      def fix_indentation heredoc
        source_lines = heredoc.split("\n")
        fixed_lines = []

        current_indentation_level = 0
        # walk backwards and fix the indentation of each line
        source_lines.reverse_each do |line|
          indentation = line[/\A */]
          indentation_size = indentation.size

          current_indentation = "  " * current_indentation_level
          # if the line is empty, then add an empty line (strip the indentation)
          fixed_lines << if line[/\A *\z/]
            ""
          else
            current_indentation + line.strip
          end

          # if the line is "end" then we need to increase the indentation level
          if line.strip == "end"
            current_indentation_level += 1

          # if the line is the end of a heredoc then we need to increase the indentation level
          elsif line.strip[/\A[A-Z]+(_[A-Z]+)*\z/]
            current_indentation_level += 1

          # if the line has indentation, then this denotes a place in the heredoc
          # where we were actually adding indentation, this is the point where we
          # decrease the indentation level again
          elsif indentation_size == 2

            current_indentation_level -= 1

          # any other indentation size means we have used the wrong heredoc type
          # or have made some other mistake
          elsif indentation_size != 0
            raise "Unexpected indentation size: #{indentation_size}"
          end
        end

        fixed_lines.reverse!

        # if the first line is not indentation of 0, then there was a problem
        if fixed_lines.first[/\A */].size != 0
          raise "Unexpected indentation size for first line of \n#{heredoc}"
        end

        fixed_lines.join("\n") + "\n"
      end
    end
  end
end
