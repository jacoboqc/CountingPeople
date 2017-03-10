from cmd import Cmd

class Persona:
    def __init__(self, pelo, sexo, altura, gafas, pantalon, zapato):
        self.pelo = pelo
        self.sexo = sexo
        self.altura = altura
        self.gafas = gafas
        self.pantalon = zapato

    def __eq__(self, otra):
        # compares wether values of attributes are equal
        return self.__dict__ == otra.__dict__

class Prompt(Cmd):
    def do_hello(self, args):
        """ Say hello, and print your args """
        print("Hello,{}".format(args))

    def do_quit(self, args):
        """ Simply quits the prompt """
        print("Quitting")
        raise SystemExit

    def do_p(self, args):
        """ Entring person. """
        features = args.split() 
        if(len(features) < 6):
            print("Uso: p PELO SEXO ALTURA GAFAS PANTALON ZAPATO")
            print(len(features))
        else: 
            person = Persona(features[0], features[1], features[2], features[3],
                    features[4], features[5])
            


if __name__ == '__main__':
    prompt = Prompt()
    prompt.prompt = '> '
    prompt.cmdloop('Starting prompt...')

lista_personas = []

    
