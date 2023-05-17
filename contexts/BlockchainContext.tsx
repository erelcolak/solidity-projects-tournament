import { tournamentContractABI, tournamentContractAddress } from "@/utils/blockchainConstants";
import { ethers } from "ethers";
import { useState, useEffect, useContext, createContext } from "react";

const BlockchainContext = createContext();

const BlockchainContextProvider = (props) => {
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  const [signer, setSigner] = useState(null);

  return (
    <BlockchainContext.Provider
      value={{
        provider,
        contract,
        signer,
        setBlockchainTools,
        assignRoleToUser,
      }}
    >
      {props.children}
    </BlockchainContext.Provider>
  );
};

export { BlockchainContext, BlockchainContextProvider };
