FROM --platform=linux/amd64 archlinux:latest

RUN sed -i 's/^DownloadUser/#DownloadUser/' /etc/pacman.conf && \
    sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf && \
    pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo dialog

RUN useradd -m -G wheel testuser && \
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY . /opt/arch/
RUN chown -R testuser:testuser /opt/arch

ENV INSTALLER_MODE=docker
WORKDIR /opt/arch
