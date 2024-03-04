%EVALFILE	Read any file and evaluate it as MATLAB code.
%
% Usage:
%    eval_file_name = '/usr/myself/foo.bar'; evalfile;
%
% Using the variable 'eval_file_name', read the file and evaluate
% it as MATLAB code.  This is handy when the file name may not end 
% in .m or may contain funny characters like '.' or '-'.
%
% Any variables in the file will appear in the current context
% (unless of course they're declared global), and likewise code
% in the file may refer to any variables currently visible.
% For this reason, this module must be a script and not a function.
%
% WARNING!  On non-Unix machines (Macintosh, PC, etc.), each line of the
% file is evaluated separately, so any statement extending over several
% lines (like most 'for' loops and 'if' statements) will not work.

% Note: Because this is a script, there are no local variables.
% Thus local variable names start with 'ef_' to avoid name collisions.

done = 0;				% set to 1 if unix version succeeds
if (isunix)
  % In Unix, it's easy to do with symbolic links.
  ef_temp = tempname;			% usually in /tmp
  if (eval_file_name(1) ~= filesep)
    eval_file_name = [pwd, filesep, eval_file_name];
  end
  if (~unix(['ln -s ', eval_file_name, ' ', ef_temp, '.m', ]))
    ef_origdir = cd(pathDir(ef_temp));	% cd returns old directory name
    eval(pathFile(ef_temp));
    if (~unix(['/bin/rm ', ef_temp, '.m']))
      cd(ef_origdir);			% go back to where we came from
      done = 1;
    end
  end
end

if (~done)
  % On Mac, DOS, and other machines, have to eval it line-by-line.
  [ef_fd,ef_msg] = fopen(eval_file_name, 'r');
  if (ef_fd < 0)
    error(sprintf('Osprey: Can''t open file ''%s'', %s \n     ''%s''',...
	eval_file_name, 'error message was', ef_msg));
  end
  ef_text = setstr(fread(ef_fd, inf, 'char').');
  fclose(ef_fd);
  
  ef_start = [0, find(ef_text == 10 | ef_text == 13)];
  for ef_i = 1:length(ef_start)-1
    eval(ef_text(ef_start(ef_i)+1 : ef_start(ef_i+1)-1));
  end
end
