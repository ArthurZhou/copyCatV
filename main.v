module main

import os
import log
import time

fn cp_all(src string, dst string, overwrite bool, mut logger log.Log) ! {
	source_path := os.real_path(src)
	logger.info(source_path)
	dest_path := os.real_path(dst)
	if !os.exists(source_path) {
		return error('Source path does not exist')
	}
	// single file copy
	if !os.is_dir(source_path) {
		if os.is_readable(source_path) {
			file_name := os.file_name(source_path)
			adjusted_path := if os.is_dir(dest_path) {
				os.join_path_single(dest_path, file_name)
			} else {
				dest_path
			}
			if os.exists(adjusted_path) {
				if overwrite {
					os.rm(adjusted_path)!
				} else {
					return error('Destination file path already exist')
				}
			}
			os.cp(source_path, adjusted_path)!
		} else {
			logger.error('Target unreadable: ' + source_path)
		}
		return
	}
	if !os.exists(dest_path) {
		os.mkdir(dest_path)!
	}
	if !os.is_dir(dest_path) {
		return error('Destination path is not a valid directory')
	}
	if os.is_readable(source_path) {
		files := os.ls(source_path)!
		if files.len > 0 {
			if files[0] != '' {
				for file in files {
					sp := os.join_path_single(source_path, file)
					dp := os.join_path_single(dest_path, file)
					if os.is_dir(sp) {
						if !os.exists(dp) {
							os.mkdir(dp)!
						}
					}
					cp_all(sp, dp, overwrite, mut logger) or {
						os.rmdir(dp) or { logger.error(err.str()) }
						logger.error(err.str())
					}
				}
			} else {
				logger.error('Unable to copy directory: ' + source_path)
			}
		} else {
			logger.info('Empty directory: ' + source_path)
		}
	} else {
		logger.error('Directory unreadable: ' + source_path)
	}
}

fn bind(target string, destination string, time_name string, mut logger log.Log) {
	logger.warn('Target: ' + target + '  Destination: ' + destination)
	auth := '27c2c59b-7a97-448d-8f41-df97fdaf89a1'
	auth2 := '9bab544d-50dc-45d2-80fa-06d1b26ab2da'

	for true {
		if os.exists(target) && !os.exists(os.join_path(target, '.copyCat')) {
			logger.warn('Starting operation...')
			cp_all(target, os.join_path(destination, time_name), true, mut logger) or {
				logger.error(err.str())
			}
			logger.warn('Done')
			break
		} else if os.exists(target) && os.exists(os.join_path(target, '.copyCat')) {
			check := os.read_file(os.join_path(target, '.copyCat')) or {
				logger.error('Failed to read .copyCat file: ' + err.str())
				return
			}
			if check == auth {
				logger.info("Pass")
			} else if check == auth2 {
				logger.info("Move")
				move(mut logger, target, destination, time_name)
			} else {
				logger.warn('Starting operation...')
				cp_all(target, os.join_path(destination, time_name), true, mut logger) or {
					logger.error(err.str())
				}
				logger.warn('Done')
			}
			break
		} else {
			time.sleep(1e+10)
		}
	}
}

fn move(mut logger log.Log, target string, destination string, time_name string) {
	logger.warn('Copying result to ' + target)
	cp_all(destination, os.join_path(target, 'copyCat-' + time_name), true, mut logger) or {
		logger.error(err.str())
	}
	os.rmdir_all(destination) or { logger.error('Failed to delete dir locally: ' + err.str()) }
}

fn start(target string, destination string, logg log.Log) {
	mut logger := logg
	for true {
		mut start_time := time.now()
		mut time_name := target.replace(":", "").replace("\\", "") + "+" + start_time.str().replace(' ', 'T').replace(':', '-')
		bind(target, destination, time_name, mut logger)
		for true {
			if !os.exists(target) {
				logger.warn('Target exited!')
				time_name = target.replace(":", "").replace("\\", "") + "+" + time.now().str().replace(' ', 'T').replace(':', '-')
				logger.warn('Next operation will copy files to: ' + time_name)
				break
			}
			time.sleep(1e+10)
		}
	}
}

fn main() {
	defer {
		println('Exiting...')
		exit(0)
	}
	println('Starting copyCatV')
	mut target := ['F:\\', 'G:\\', 'H:\\', 'I:\\', 'J:\\', 'V:\\']
	mut destination := '.\\desti'
	if os.args.len != 1 {
		if os.args[1] != '_' {
			destination = os.args[1]
		}
	}
	if os.args.len > 2 {
		mut item := 0
		for true {
			target << os.args[item + 2]
			item++
			if item + 2 == os.args.len {
				break
			}
		}
		println(target)
	}

	if !os.exists(destination) {
		os.mkdir(destination) or { panic(err) }
	}

	mut start_time := time.now()
	mut time_name := start_time.str().replace(' ', 'T').replace(':', '-')

	mut logger := log.Log{}
	logger.set_level(log.Level.info)
	logger.set_full_logpath(os.join_path(destination, time_name + '.log'))
	logger.log_to_console_too()

	for t in target {
		go start(t, destination, logger)
	}

	for true {
		time.sleep(6e+10)
	}

	logger.warn('Now Exiting...')
}
