Make a user prompt for installation process for
# My personal(Hatta) Desktop configuration
the prompt installation would ask for an option

-Do you want to use Hatta terminal setup or just bare omaterm-lite installation?
-Server obviously stayed minimal as a server installation


1. Install Oh My Zsh 
```
```
```curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)```
- I think when the user start installing Oh My Zsh, it would make sure the user would start walking through the installation wizard for confirming a proper in terminal contents render like fancy fonts in nerdfonts in the terminal... Make sure the user to do the wizard so the render features of oh my zsh for the user would be accordingly to their setup

2. Install p10k
- git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

3. Install forgecode
```curl -fsSL https://forgecode.dev/cli | sh```

Take note that I(Hatta) used a customized p10k configuration utilizing forgecode interface on it...

Refer for a fix I did to make the full completed setup clean
~/github/my-laptop-problem-fix/Forge_ZSH_Tmux_Completion_Fix.md
~/github/my-laptop-problem-fix/Forge_ZSH_P10k_Prompt_Refresh_Fix.md

Refer the completed configuration for both Oh My Zsh and p10k in HOME...

I want user that choose to use Hatta configuration installation process would have the same configuration utilizing the forgecode inside their terminal without walking through the p10k installation setup wizard

Save all the configs that will be used for installation in https://github.com/hattapauzi/omadots since that repo is used to save other configs for this repo setup install
