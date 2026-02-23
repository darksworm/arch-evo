FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo dialog

RUN useradd -m -G wheel testuser && \
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY . /opt/arch/

ENV INSTALLER_MODE=docker
WORKDIR /opt/arch
