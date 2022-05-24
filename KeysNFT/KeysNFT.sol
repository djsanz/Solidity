// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KeysNFT is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;
	uint256 public fee = 0.1 ether;

	struct Conf {
        uint8 mint;
        uint8 juego;
    }
    Conf [4] public Configs;

	struct Key {
        uint256 id;
        uint8 rarity;
    }
    Key [] private Keys;
	
	uint8 public ProcentPremio = 70;

	// Eventos
    event NewKey(address indexed owner, uint256 id, uint8 rarity);
    event NewWin(address indexed owner, uint256 premio);

    constructor() ERC721("KeysNFT", "Keys") {
        // Conf memory newConf = Conf(1, 50,10);
        SetConfig(1,50,10);
        SetConfig(2,35,30);
        SetConfig(3,15,50);
    }
	
    function SetProcentPremio(uint8 Num) public onlyOwner(){
        ProcentPremio = Num;
    }

    function SetConfigs(Conf [] memory Array) public onlyOwner{
        //Default  [[50,10],[35,30],[15,50]]
        for (uint8 i = 0; i <= 2; i++) {
            SetConfig(i+1,Array[i].mint,Array[i].juego);
        }
    }

    function SetConfig(uint8 Rarity,uint8 Mint,uint8 Juego) internal{
        Configs[Rarity] = Conf(Mint,Juego);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
	
	// Creacion de las LLaves
    function safeMint(address to, uint256 Seed) internal {
		uint8 rand = uint8(_createRandomNum(100,Seed));
		//15% -> Rarity = 3
		//35% -> Rarity = 2
		//50% -> Rarity = 1
        uint8 Rarity3Prop = 100 - Configs[3].mint;
        uint8 Rarity2Prop = (100-Configs[2].mint-Configs[3].mint);
		uint8 Rarity = 1;
		if (rand > Rarity3Prop){Rarity = 3;}
		else if(rand > Rarity2Prop){Rarity = 2;}
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
		Key memory newKey = Key(tokenId, Rarity);
        Keys.push(newKey);
        _safeMint(to, tokenId);
		emit NewKey(msg.sender, tokenId, Rarity);
    }
	
    //Carga Contrato
    function CargaContrato() public payable onlyOwner returns (bool){
        return true;
    }

	//Crea Llave Pagando
    function createRandomKey() public payable {
        require(msg.value >= fee);
        safeMint(msg.sender,0);
		address payable _owner = payable(msg.sender);
        _owner.transfer(msg.value - fee);
    }
	
	//Crea Muchas Llaves Pagando
    function createRandomKeyMulti() public payable {
        require(msg.value >= fee);
        uint256 Cant = msg.value / fee;
        uint256 Veces = 0;
        for (uint i = 1; i <= Cant; i++) {
            safeMint(msg.sender,Veces);
            Veces++;
        }
        address payable _owner = payable(msg.sender);
        _owner.transfer(msg.value - (fee * Veces));
    }

	//Owner Crea Llave Gratis para alguien
    function MintRandomKey(address to) public onlyOwner {
        safeMint(to,0);
    }
	
	// Obtención de los tokens NFT usuario
    function getOwnerKeys() public view returns (Key [] memory) {
        Key [] memory result = new Key [] (balanceOf(msg.sender));
        uint256 counter = 0;
        for (uint256 i = 0; i <Keys.length; i++) {
            if (_exists(i)){
                if (ownerOf(i) == msg.sender) {
                    result[counter] = Keys[i];
                    counter++;
                }
            }
        }
        return result;
    }
	
	// Funciones De Ayuda
	// Asignación de un número aleatorio
    function _createRandomNum(uint8 _mod,uint256 Seed) internal view returns (uint8) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender,_mod,Seed)));
        uint256 randomNum2 = uint256(keccak256(abi.encodePacked(randomNum,block.number,_tokenIdCounter.current())));
        uint256 randomNum3 = uint256(keccak256(abi.encodePacked(block.difficulty,Seed,randomNum2)));
        return uint8(randomNum3 % _mod) + 1;
    }

	
	// Actualización del precio del Token NFT
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
	
	// Visualizar el balance del Smart Contract 
    function moneySmartContract() public view returns (uint256){
        return address(this).balance;
    }
	
	// Extracción de los ethers del Smart Contract hacia el Owner 
    function withdraw() external payable onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    function GetPremio() public view returns (uint256){
        // require(address(this).balance >0);
		uint256 Balance = address(this).balance;
		uint256 Premio = 0;
		if (Balance > 0){
			Premio = (Balance * ProcentPremio)/100;
		}
        return Premio;
    }

    function Juega(uint256 tokenId) public payable returns (bool){
        require(_isApprovedOrOwner(msg.sender, tokenId));
        uint8 Rarity = Keys[tokenId].rarity;
        uint8 PriceNumber = Configs[1].juego;
        if (Rarity == 2){
            PriceNumber = Configs[2].juego;
        }else if(Rarity == 3){
            PriceNumber = Configs[3].juego;
        }
        uint8 WinNumber = _createRandomNum(100,0);
        bool Resultado = false;
        if (PriceNumber > WinNumber){
            Resultado = true;
            address payable _Ganador = payable(msg.sender);
            uint256 Premio = GetPremio();
            _Ganador.transfer(Premio);
            emit NewWin(msg.sender, Premio);
        }
        burn(tokenId);
        return Resultado;
    }
}