import sys
import subprocess
import shutil
import time
from pathlib import Path

def getAbbr(org):
    words = org.split()
    abbr = ""
    for word in words:
        abbr += word[0]
    abbr = abbr.title()
    return abbr

def readFileLines(fileName):
    lines = []
    with open(fileName, "r") as file:
        for line in file:
            if (len(line) > 0 and line != '\n'):
                if (line[-1] == '\n'):
                    line = line[:-1]
                lines.append(line)

    return lines

start_time = time.time()

print(time.strftime("%H:%M:%S", time.localtime()))
print("Запущен конвейер по обработке выборок")

args_list = sys.argv

artsite_file_name = args_list[1]
print("Имя входного файла (ARTSITE): " + artsite_file_name)
print()

tf_file = args_list[2]
print("Получаем имена транскрипциооных факторов из файла ", tf_file)
tf_list = readFileLines(tf_file)
print("Транскрипционные факторы: ", tf_list)
print()

orgs_file = args_list[3]
print("Получаем названия организмов из файла ", orgs_file)
orgs_list = readFileLines(orgs_file)
print("Организмы: ", orgs_list)
print()

print("Создаём директории для вывода программы (Организм_ТФактор_EntrezОграничение)")
for tf in tf_list:
    for org in orgs_list:
        for entr in orgs_list:
            dir_name = tf + "/" + getAbbr(org) + "_" + tf + "_" + getAbbr(entr)
            Path(dir_name).mkdir(parents=True, exist_ok=True)
            print(dir_name + " done")
print()

print("Запуск парсера ARTSITE (" + artsite_file_name + ") -> FASTA (input.fst)")
subprocess.run(['./parser'])
print()

print("Разбиение данных на выборки input.fst -> TFID_org.fst ...")
for tf in tf_list:
    for org in orgs_list:
        path_start = tf + "/" + getAbbr(org) + "_" + tf + "_"
        init_path = path_start + getAbbr(orgs_list[0])
        selector_file_name = tf + "_" + getAbbr(org) + ".fst"
        subprocess.run(['./selector', tf, getAbbr(org), "input.fst", init_path + "/" + selector_file_name])

        for i in range (1, len(orgs_list)):
            new_path = path_start + getAbbr(orgs_list[i])
            shutil.copy(init_path + "/" + selector_file_name, new_path)
            print(init_path + "/" + selector_file_name + " copied to " + new_path)
print()

output_list = []
commands = []
procs = []

print("Запуски:")
# Для каждого транскрипционного фактора...
for tf in tf_list:
    # ... и каждого организма есть входной файл
    for org in orgs_list:
        infile = tf + "_" + getAbbr(org) + ".fst"
        for entr in orgs_list:
            org_entrez = entr + "[Organism]"
            input_path = tf + "/" + getAbbr(org) + "_" + tf + "_" + getAbbr(entr)
            input_file = input_path + "/" + infile
            command = ['./test', '-program', 'blastn', '-infile', input_file, '-entrez', org_entrez, '-outDir', input_path, '-db', 'refseq_genomes']
            print(command)
            commands.append(command)
            procs.append(subprocess.Popen( command, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
            outfile = input_path + "/" + getAbbr(org) + tf + getAbbr(entr)
            output_list.append(outfile)
            print("waiting 5 sec")
            time.sleep(5)
            #break

        #break
print()
print("Все запуски запущены")
print(time.strftime("%H:%M:%S", time.localtime()))

current_procs_count = len( procs )
done_numbers = []
error_counter = 0
isRestartAllowed = True

# Проверка готовности запуска и его перезапуск при ошибке
while current_procs_count > 0:
    time.sleep(30)

    if (time.time() - start_time > 28800):
        for p in procs:
            p.terminate()
        break

    if (error_counter > 90):
        isRestartAllowed = False

    removed_count = 0
    for i in done_numbers:
        procs.pop(i - removed_count)
        print("Число процессов: ", len( procs ))
        removed_count = removed_count + 1
        current_procs_count = current_procs_count - 1

    done_numbers = []
    current_procs_count = len( procs )

    for i in range(current_procs_count):
        p = procs[i]

        if (p.poll() is None):
            continue

        print(time.strftime("%H:%M:%S", time.localtime()))
        output, err = p.communicate()

        if (err):
            command = p.args
            
            print("Запуск упал: ", p.args)
            err_line = err.decode()
            print(err_line)
            if ("Empty TSeqLocVector" in err_line):
                print("Этот запуск не будет перезапущен, ошибка возникла из-за пустого входного файла")
            else:
                error_counter = error_counter + 1
                if (isRestartAllowed):
                    print("Перезапускаем")
                    procs.append(subprocess.Popen( command, stdout=subprocess.PIPE, stderr=subprocess.PIPE))
                    time.sleep(10)
        else:
            print("Запуск успешно завершён: ", p.args)

        done_numbers.append(i)

        out_dir = p.args[8]

        err_file = open(out_dir + "/stderr.txt", "wb") 
        out_file = open(out_dir + "/stdout.txt", "wb") 

        err_file.write(err)
        out_file.write(output) 

        err_file.close() 
        out_file.close()       
