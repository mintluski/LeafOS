================================================================
  LeafOS v1.0-LTS - Documentacao (Portugues)
================================================================

1. VISAO GERAL
--------------
LeafOS e uma distribuicao Linux leve baseada em BusyBox e no
ecossistema de pacotes Alpine Linux. Projetada para maquinas
virtuais, sistemas embarcados e ambientes minimalistas.

  - Kernel: Linux 6.19.6
  - Init: Script shell customizado
  - Shell: BusyBox ash
  - Gerenciador de pacotes: Alpine APK (25.000+ pacotes)
  - Sistema de arquivos: ext2
  - Bootloader: GRUB 2

2. COMO INICIALIZAR
-------------------
a) A partir do ISO (Modo Live):
   qemu-system-x86_64 -m 256 -cdrom leafos-v1.0-LTS.iso \
       -net nic,model=e1000 -net user -nographic

b) A partir do disco instalado:
   qemu-system-x86_64 -m 256 -hda leafos-disk.qcow2 \
       -net nic,model=e1000 -net user -nographic

c) Com interface grafica:
   qemu-system-x86_64 -m 256 -cdrom leafos-v1.0-LTS.iso \
       -net nic,model=e1000 -net user

3. COMO INSTALAR
----------------
a) Inicialize a partir do ISO
b) No prompt do shell, digite: leafos-install
c) Siga as instrucoes interativas:
   - Selecione o disco alvo (ex: /dev/sda)
   - Escolha o layout do teclado (padrao: us)
   - Confirme a instalacao
d) O instalador ira:
   - Particionar o disco
   - Formatar como ext2
   - Copiar os arquivos do sistema
   - Instalar o bootloader GRUB
   - Configurar o sistema
e) Remova o ISO e reinicie

Para instalacao automatizada, crie /autoinstall.conf:
   AUTO_MODE=1
   AUTO_DISK="/dev/sda"
   AUTO_KEYBOARD="br-abnt2"

4. COMO INSTALAR PACOTES
-------------------------
LeafOS usa o gerenciador de pacotes APK do Alpine Linux.

  # Atualizar indice de pacotes
  apk update

  # Buscar um pacote
  apk search <nome>

  # Instalar um pacote
  apk add <pacote>

  # Remover um pacote
  apk del <pacote>

  # Listar pacotes instalados
  apk info

  # Instalar sem cache
  apk add --no-cache <pacote>

Exemplos:
  apk add curl        # Cliente HTTP
  apk add htop        # Visualizador de processos
  apk add nano        # Editor de texto
  apk add openssh     # Servidor/cliente SSH
  apk add python3     # Python 3

5. COMANDOS DO SISTEMA
----------------------
  leafos-help      Mostrar comandos disponiveis
  leafos-info      Mostrar informacoes do sistema
  leafos-version   Mostrar versao
  leafos-install   Instalar no disco

6. RECUPERACAO DO SISTEMA
-------------------------
Se o sistema nao conseguir inicializar:

a) Inicialize pelo ISO no modo de recuperacao:
   - Selecione "LeafOS v1.0-LTS (Rescue Shell)" no menu GRUB

b) Monte o sistema instalado:
   mount /dev/sda1 /mnt

c) Corrija problemas:
   - Edite /mnt/etc/fstab para problemas de montagem
   - Edite /mnt/init para problemas de inicializacao
   - Verifique /mnt/boot/grub/grub.cfg para configuracao de boot

d) Reinstalar bootloader:
   - Inicialize pelo ISO
   - Monte o disco: mount /dev/sda1 /mnt
   - Copie GRUB: dd if=/usr/lib/grub/i386-pc/boot.img of=/dev/sda bs=440 count=1
   - Copie core: dd if=/usr/lib/grub/i386-pc/core_tiny.img of=/dev/sda bs=512 seek=1

e) Chroot no sistema instalado:
   mount -t proc proc /mnt/proc
   mount -t sysfs sysfs /mnt/sys
   mount -o bind /dev /mnt/dev
   chroot /mnt /bin/sh

7. CONFIGURACAO DE REDE
------------------------
  - DHCP e configurado automaticamente via udhcpc
  - Resolvedores DNS: /etc/resolv.conf
  - No QEMU, use: -net nic,model=e1000 -net user

8. INFORMACOES DE VERSAO
-------------------------
  Versao:   v1.0-LTS
  Codinome: LeafOS
  Release:  Suporte de Longo Prazo (LTS)
  Kernel:   6.19.6
  BusyBox:  1.31.1
  APK:      2.14.6

================================================================
  LeafOS v1.0
================================================================
