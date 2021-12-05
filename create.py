import sys

argumentos = sys.argv

nr = 100
nc = 100
dt = 6
dx = 0.01
alpha = "1e-6"

if (len(argumentos) > 1):
    if("-fn" or "--numbers" in argumentos):
        if((nri := argumentos.index("-nr")) != -1):
            try:
                nr = int(argumentos[nri + 1])
            except Exception as e:
                print("error nr "+str(e))
                exit()
        if((nci := argumentos.index("-nc")) != -1):
            try:
                nc = int(argumentos[nci + 1])
            except Exception as e:
                print("error nc "+str(e))
                exit()

        if((dti := argumentos.index("-dt")) != -1):
            try:
                dt = float(argumentos[dti + 1])
            except Exception as e:
                print("error dt "+str(e))
                exit()

        if((dxi := argumentos.index("-dx")) != -1):
            try:
                dx = float(argumentos[dxi + 1])
            except Exception as e:
                print("error dx "+str(e))
                exit()
        if((ai := argumentos.index("-a")) != -1):
            try:
                alpha = (argumentos[ai + 1])
            except Exception as e:
                print("error a "+str(e))
                exit()

        testarr = []
        for i in range(nc):
            for j in range(nr):
                if(j < nr/2):
                    testarr.append(1200)
                else:
                    testarr.append(300)

        texttest = str(testarr).replace(
            "[", "").replace("]", "").replace(" ", "")

        f = open("test", "w")
        f.write(str(nr)+"\n")
        f.write(str(nc)+"\n")
        f.write(str(dt)+"\n")
        f.write(str(dx)+"\n")
        f.write(texttest+"\n")
        f.write(str(alpha))
        f.close()

        f1 = open("testnum", "w")
        f1.write(texttest)
        print("OK :)")

    if("--graph" or "fg" in argumentos):
        testarr = []
        for i in range(100):
            for j in range(100):
                if(j < nr/2):
                    testarr.append([j, i, 1200])
                else:
                    testarr.append([j, i, 300])

        texttest = str(testarr).replace("],", "\n").replace(
            "]", "").replace("[", "").replace(" ", "").replace(",", " ")

        f = open("testgraph", "w")
        f.write(texttest)
        f.close()

    else:
        print("a")
