 Es un sistema de comunicación con texto entre tres dispositivos. Serás capaz de escribir el mensaje mediante un teclado matricial incluido en cada dispositivo. Podrás enviar mensajes al instante a uno o dos dispositivos desde el tuyo, para poder comunicarte efectivamente sin necesidad de hablar.

 Descripción Técnica:

 El circuito tendrá las siguientes funciones:
 •	Uso del puerto serial incorporado en el AT89S52 tanto para la recepción como para la transmisión de los mensajes.
 •	Como medios de interacción con el usuario contaremos con un teclado matricial, push buttons, y dip switches.
 •	Los LCD’s serán los encargados del despliegue de los mensajes recibidos y enviados.

Modos de funcionamiento:

 Se tienen dos modos principales de funcionamiento: envío y recepción de mensajes; se puede acceder a ambos desde el programa principal, ya que en el chat estará en modo de recepción a menos que se esté editando o enviando un mensaje.

 Habrá un chat grupal, en el que los tres microcontroladores podrán "hablar" entre todos, pudiendo ver quién fue el remitente del mensaje.
 Cada dispositivo tendrá un identificador único, un número entero, con el que se podrán identificar sus mensajes.

 Los mensajes serán mostrados en la pantalla LCD al ser recibidos.

Listado de Hardware:

 •	Tres microcontroladores AT89S52.
 •	Tres pantallas de tipo LCD.
 •	Tres teclados matriciales.
 •	Tres componentes 74LC922.
 •	Push buttons
 •	Dip switches
