# Samsung Galaxy Book Linux - Configuração Unificada

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04+-orange.svg)](https://ubuntu.com/)
[![Kernel](https://img.shields.io/badge/Kernel-6.14.0+-blue.svg)](https://kernel.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Este repositório unifica as configurações e drivers necessários para executar Linux no Samsung Galaxy Book com funcionalidades completas. Combina as melhores práticas dos repositórios [galaxy-book2-pro-linux](https://github.com/joshuagrisham/galaxy-book2-pro-linux) e [samsung-galaxybook-extras](https://github.com/joshuagrisham/samsung-galaxybook-extras).

## 📋 Índice

- [Modelos Suportados](#-modelos-suportados)
- [Requisitos do Sistema](#-requisitos-do-sistema)
- [Instalação Rápida](#-instalação-rápida)
- [Instalação Manual](#-instalação-manual)
- [Funcionalidades](#-funcionalidades)
- [Solução de Problemas](#-solução-de-problemas)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Contribuição](#-contribuição)
- [Licença](#-licença)

## 🖥️ Modelos Suportados

### ✅ Testados e Funcionais
- **NP950XEE** - Galaxy Book2 Pro 360 (13.3")
- **NP950XED** - Galaxy Book2 Pro (13.3")
- **NP950XDB** - Galaxy Book2 Pro (15.6")
- **NP950XCJ** - Galaxy Book2 Pro 360 (15.6")
- **NP950QDB** - Galaxy Book2 Pro (15.6")

### ⚠️ Suporte Experimental
- **NP750XFH** - Galaxy Book Pro 360 (13.3")
- **NP750XGJ** - Galaxy Book Pro (13.3")
- **NP960XFH** - Galaxy Book3 Pro 360 (13.3")

## 🔧 Requisitos do Sistema

### Sistema Operacional
- **Ubuntu 22.04+** (testado em 24.04)
- **Kernel Linux 6.14.0+** (recomendado para funcionalidades completas)
- **Kernel 6.2.0+** (funcionalidades básicas)

### Hardware
- Samsung Galaxy Book (modelos listados acima)
- Pelo menos 4GB de RAM
- 10GB de espaço livre em disco

### BIOS/UEFI
- **Secure Boot**: Desabilitado OU configurado para "Secure Boot Supported OS"
- **Fast Boot**: Desabilitado
- **Legacy Boot**: Desabilitado (UEFI apenas)

## 🚀 Instalação Rápida

### Método 1: Script Automatizado (Recomendado)

```bash
# 1. Baixar o projeto
git clone https://github.com/seu-usuario/samsung-galaxybook-linux-unified.git
cd samsung-galaxybook-linux-unified

# 2. Executar script de instalação
chmod +x install.sh
./install.sh

# 3. Reiniciar o sistema
sudo reboot
```

### Método 2: Instalação Manual

Siga os passos detalhados na seção [Instalação Manual](#-instalação-manual).

### Verificação de Instalação

Após a instalação, verifique se tudo está funcionando:

```bash
# Verificar GPU Intel
./verify-gpu.sh

# Verificar dispositivos OpenCL
clinfo | grep "Device Name"

# Verificar drivers de mídia
vainfo

# Verificar impressão digital
lsusb | grep "1c7a:0582"
```

## 📖 Instalação Manual

### Passo 1: Preparação do Sistema

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
    dkms \
    git \
    curl \
    wget \
    acpica-tools \
    powertop \
    fprintd \
    libfprint-2-2 \
    libfprint-2-dev \
    libpam-fprintd \
    lsb-release
```

### Passo 2: Configuração do Teclado

```bash
# Copiar configuração do teclado
sudo cp 61-keyboard-samsung-galaxybook.hwdb /etc/udev/hwdb.d/

# Atualizar banco de dados de hardware
sudo systemd-hwdb update
sudo udevadm trigger
```

### Passo 3: Configuração de Áudio

```bash
# Criar configuração de áudio
sudo tee /etc/modprobe.d/audio-fix.conf > /dev/null <<EOF
# Samsung Galaxy Book Audio Configuration
options snd-hda-intel model=alc298-samsung-amp-v2-2-amps
EOF
```

### Passo 4: Configuração do GRUB

```bash
# Backup do GRUB
sudo cp /etc/default/grub /etc/default/grub.backup

# Adicionar parâmetros do kernel
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dpcd_backlight=3 i915.enable_dp_mst=0 i915.enable_psr2_sel_fetch=1 /' /etc/default/grub

# Atualizar GRUB
sudo update-grub
```

### Passo 5: Configuração da Impressão Digital

```bash
# Verificar se o dispositivo está presente
lsusb | grep "1c7a:0582"

# Cadastrar impressão digital
fprintd-enroll
```

### Passo 6: Instalação dos Drivers de GPU Intel

```bash
# Verificar versão do Ubuntu
lsb_release -a

# Para Ubuntu 24.04+ (recomendado)
sudo apt-get update
sudo apt-get install -y software-properties-common

# Adicionar PPA Intel Graphics
sudo add-apt-repository -y ppa:kobuk-team/intel-graphics

# Instalar pacotes de computação
sudo apt-get install -y libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd clinfo intel-gsc

# Instalar pacotes de mídia
sudo apt-get install -y intel-media-va-driver-non-free libmfx-gen1 libvpl2 libvpl-tools libva-glx2 va-driver-all vainfo

# Para desenvolvimento (PyTorch, etc.)
sudo apt-get install -y libze-dev intel-ocloc

# Para ray tracing (opcional)
sudo apt-get install -y libze-intel-gpu-raytracing

# Adicionar usuário ao grupo render
sudo gpasswd -a ${USER} render
newgrp render
```

### Passo 7: Otimização de Bateria

```bash
# Configurar PowerTOP
sudo systemctl enable powertop.service

# Calibrar PowerTOP (opcional)
sudo powertop --calibrate
```

## ✨ Funcionalidades

### ⌨️ Teclado
- **Teclas de Função**: Fn+F1 (Configurações), Fn+F5 (Touchpad), Fn+F7/F8 (Volume)
- **Backlight do Teclado**: Controle automático via driver samsung-galaxybook
- **Layout**: Suporte completo para pt-br abnt2
- **CapsLock**: Funcionamento correto em todas as aplicações

### 🔊 Áudio
- **Alto-falantes**: Suporte para ALC298 com amplificadores Samsung
- **Entrada 3.5mm**: Funcionamento completo
- **Bluetooth**: Suporte nativo
- **USB Audio**: Funcionamento em portas USB-A e USB-C

### 🖥️ Display
- **Brilho da Tela**: Controle funcional via `i915.enable_dpcd_backlight=3`
- **OLED**: Suporte completo para displays OLED
- **Resolução**: Suporte para resoluções nativas

### 🔐 Impressão Digital
- **Dispositivo**: Egis Technology (LighTuning) Match-on-Chip (ID 1c7a:0582)
- **Driver**: libfprint com suporte experimental
- **Funcionalidades**: Login, sudo, autenticação

### ⚡ Bateria
- **Duração**: 5-7 horas de uso normal
- **Otimização**: PowerTOP com auto-tune
- **Carregamento**: Parada automática em 85% (configurável no BIOS)

### 🔌 Thunderbolt
- **Porta**: USB-C (mais próxima da frente)
- **Dock**: Suporte para docks Thunderbolt 3/4
- **Display**: DisplayPort mais estável que HDMI
- **Power Delivery**: Funcionamento via dock

### 🎮 GPU Intel
- **Drivers**: Intel Graphics PPA com suporte completo
- **OpenCL**: Suporte para computação paralela
- **Media**: Aceleração de hardware para vídeo
- **Ray Tracing**: Suporte experimental (opcional)
- **Desenvolvimento**: PyTorch, OpenVINO, etc.

## 🔧 Solução de Problemas

### Problema: CapsLock não funciona
**Sintoma**: CapsLock produz '—' em vez de alternar maiúsculas/minúsculas

**Solução**:
```bash
# Verificar se há DSDT personalizado no GRUB
grep "acpi_override" /etc/default/grub

# Se encontrado, remover (causa comum do problema)
sudo sed -i 's/ acpi_override=\/boot\/.*\.aml//' /etc/default/grub
sudo update-grub
sudo reboot
```

### Problema: Alto-falantes não funcionam
**Sintoma**: Sem som nos alto-falantes, mas funciona em fones

**Solução**:
```bash
# Executar script de ativação
./sound/necessary-verbs.sh

# Ou usar o comando simplificado
samsung-audio-fix
```

### Problema: Brilho da tela não controla
**Sintoma**: Teclas de brilho não funcionam

**Solução**:
```bash
# Verificar parâmetros do kernel
grep "i915.enable_dpcd_backlight" /etc/default/grub

# Se não encontrado, adicionar
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dpcd_backlight=3 /' /etc/default/grub
sudo update-grub
sudo reboot
```

### Problema: Impressão digital não detectada
**Sintoma**: `lsusb` não mostra dispositivo 1c7a:0582

**Solução**:
```bash
# Verificar se o dispositivo está presente
lsusb -v | grep -A 5 -B 5 "1c7a:0582"

# Se não encontrado, pode ser problema de hardware ou BIOS
```

### Problema: Dock Thunderbolt não funciona
**Sintoma**: Dock não é reconhecido ou display não funciona

**Solução**:
```bash
# Adicionar parâmetros específicos para dock
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&i915.enable_dp_mst=0 i915.enable_psr2_sel_fetch=1 /' /etc/default/grub
sudo update-grub
sudo reboot

# Conectar dock ANTES de ligar o notebook
```

### Problema: GPU Intel não detectada
**Sintoma**: `clinfo` não mostra dispositivos Intel ou erro de permissão

**Solução**:
```bash
# Verificar se o usuário está no grupo render
groups $USER

# Se não estiver, adicionar
sudo gpasswd -a ${USER} render
newgrp render

# Verificar instalação dos drivers
clinfo | grep "Device Name"

# Verificar permissões
ls -la /dev/dri/

# Se necessário, reiniciar o sistema
sudo reboot
```

### Problema: Aceleração de hardware não funciona
**Sintoma**: Vídeos não usam aceleração de hardware

**Solução**:
```bash
# Verificar drivers de mídia
vainfo

# Verificar codecs suportados
vainfo --display drm --device /dev/dri/renderD128

# Reinstalar drivers de mídia se necessário
sudo apt-get install --reinstall intel-media-va-driver-non-free
```

## 📁 Estrutura do Projeto

```
samsung-galaxybook-linux-unified/
├── install.sh                          # Script de instalação automatizada
├── verify-gpu.sh                       # Script de verificação de GPU
├── README.md                           # Este arquivo
├── LICENSE                             # Licença MIT
├── 61-keyboard-samsung-galaxybook.hwdb # Configuração do teclado
├── dsdt/                               # Arquivos DSDT para diferentes modelos
│   ├── NP750XFH-dsdt.dsl
│   ├── NP750XGJ-dsdt.dsl
│   ├── NP950QDB-dsdt.dsl
│   ├── NP950XCJ-dsdt.dsl
│   ├── NP950XDB-dsdt.dsl
│   ├── NP950XED-dsdt.dsl
│   └── NP960XFH-dsdt.dsl
├── fingerprint/                        # Configurações de impressão digital
│   ├── egismoc-1c7a-0582.py
│   ├── egismoc-1c7a-05a5.py
│   ├── egismoc-sdcp-1c7a-0582.py
│   ├── libfprint.md
│   └── readme.md
├── sound/                              # Scripts e configurações de áudio
│   ├── necessary-verbs.sh              # Script principal de áudio
│   ├── init-*.sh                       # Scripts de inicialização
│   ├── *-on.sh / *-off.sh              # Scripts de controle
│   └── qemu/                           # Ferramentas de desenvolvimento
└── wmi/                                # Configurações WMI
    ├── DSDT.aml
    ├── DSDT.dsl
    └── *.bmf                           # Arquivos de firmware
```

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. **Fork** o repositório
2. **Crie** uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. **Commit** suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. **Push** para a branch (`git push origin feature/nova-funcionalidade`)
5. **Abra** um Pull Request

### Modelos para Teste
Estamos especialmente interessados em testar novos modelos:
- Galaxy Book3 Pro
- Galaxy Book4 Pro
- Outros modelos da série Galaxy Book

### Relatórios de Bug
Ao reportar bugs, inclua:
- Modelo exato do notebook
- Versão do Ubuntu
- Versão do kernel (`uname -r`)
- Logs relevantes (`dmesg`, `journalctl`)

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos e Créditos

### **Repositórios Originais**
Este projeto unifica e expande o trabalho dos seguintes repositórios:

- **[Joshua Grisham](https://github.com/joshuagrisham)** - Autor principal e mantenedor
- **[galaxy-book2-pro-linux](https://github.com/joshuagrisham/galaxy-book2-pro-linux)** - Base para configurações e documentação
  - 174 ⭐ stars, 13 forks
  - Configurações de áudio, impressão digital, Thunderbolt
  - Scripts de inicialização e troubleshooting
- **[samsung-galaxybook-extras](https://github.com/joshuagrisham/samsung-galaxybook-extras)** - Driver e utilitários
  - 227 ⭐ stars, 22 forks
  - Driver Linux para Samsung Galaxy Book
  - Arquivos DSDT para diferentes modelos
  - Configurações de teclado hwdb

### **Contribuições Específicas**
- **Configurações de Áudio**: Scripts `necessary-verbs.sh` e configurações ALC298
- **Impressão Digital**: Driver libfprint para Egis Technology (1C7A:0582)
- **Thunderbolt**: Parâmetros de kernel e troubleshooting
- **DSDT**: Arquivos personalizados para diferentes modelos Galaxy Book
- **Teclado**: Configurações hwdb para teclas de função Samsung

### **Recursos Externos**
- **[Intel Graphics Drivers](https://www.intel.com.br/content/www/br/pt/download/747008/intel-arc-graphics-driver-ubuntu.html)** - Drivers oficiais de GPU
- **[Intel GPU Documentation](https://dgpu-docs.intel.com/driver/client/overview.html)** - Documentação oficial
- **Comunidade Linux** - Suporte e feedback contínuo
- **Ubuntu Community** - Base do sistema operacional

### **Licenciamento**
Este projeto mantém a mesma licença MIT dos repositórios originais e reconhece todos os direitos autorais dos trabalhos originais.

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/seu-usuario/samsung-galaxybook-linux-unified/issues)
- **Discussions**: [GitHub Discussions](https://github.com/seu-usuario/samsung-galaxybook-linux-unified/discussions)
- **Wiki**: [Documentação Completa](https://github.com/seu-usuario/samsung-galaxybook-linux-unified/wiki)

---

**⭐ Se este projeto ajudou você, considere dar uma estrela! ⭐**
