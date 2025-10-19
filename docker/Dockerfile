# nrest.nvim Docker Demo Environment
# Build a lightweight container to test nrest.nvim

FROM alpine:latest

LABEL maintainer="Matthias"
LABEL description="Interactive demo environment for nrest.nvim - HTTP REST client for Neovim"
LABEL version="0.1.0"

# Install dependencies
RUN apk add --no-cache \
    neovim \
    curl \
    jq \
    git \
    bash \
    tar \
    gzip \
    ca-certificates

# Create a non-root user for running Neovim
RUN adduser -D -h /home/nvim nvim
USER nvim
WORKDIR /home/nvim

# Set up Neovim directories
RUN mkdir -p /home/nvim/.config/nvim \
    /home/nvim/.local/share/nvim/site/pack/vendor/start \
    /home/nvim/demo

# Install lazy.nvim (plugin manager)
RUN git clone --filter=blob:none https://github.com/folke/lazy.nvim.git \
    /home/nvim/.local/share/nvim/lazy/lazy.nvim

# Copy Neovim configuration
COPY --chown=nvim:nvim docker/nvim/ /home/nvim/.config/nvim/

# Copy nrest.nvim plugin (from repository root)
COPY --chown=nvim:nvim lua/ /home/nvim/.local/share/nvim/nrest/lua/
COPY --chown=nvim:nvim plugin/ /home/nvim/.local/share/nvim/nrest/plugin/
COPY --chown=nvim:nvim syntax/ /home/nvim/.local/share/nvim/nrest/syntax/
COPY --chown=nvim:nvim ftplugin/ /home/nvim/.local/share/nvim/nrest/ftplugin/

# Copy example .http files
COPY --chown=nvim:nvim docker/examples/ /home/nvim/demo/

# Set default working directory to demo folder
WORKDIR /home/nvim/demo

# Set environment variables
ENV EDITOR=nvim
ENV VISUAL=nvim

# Health check - verify Neovim can start
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD nvim --headless -c "checkhealth nrest" -c "qa" || exit 1

# Default command: Start Neovim with welcome message
CMD ["nvim", "welcome.http"]
