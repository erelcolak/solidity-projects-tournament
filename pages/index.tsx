import { BlockchainContext } from "@/contexts/BlockchainContext";
import { tournamentContractABI, tournamentContractAddress } from "@/utils/blockchainConstants";
import { ethers } from "ethers";
import { useContext, useEffect, useState } from "react";

export default function Home() {
  const [provider, setProvider] = useState<any | null>(null);
  const [contract, setContract] = useState<any | null>(null);
  const [signer, setSigner] = useState<any | null>(null);
  const [account, setAccount] = useState<any | null>([]);
  const [username, setUsername] = useState("");
  const [userAddress, setUserAddress] = useState("");
  const [tournamentId, setTournamentId] = useState("");
  const [tournamentName, setTournamentName] = useState("");
  const [donationAmount, setDonationAmount] = useState("");

  const connectToMetamask = async () => {
    const _provider = new ethers.providers.Web3Provider(window.ethereum);
    const _accounts = await _provider.send("eth_requestAccounts", []);
    setAccount(_accounts[0]);
  };
  const setBlockchainTools = async () => {
    const _provider = new ethers.providers.Web3Provider(window.ethereum);
    const _signer = _provider.getSigner();
    const _contract = new ethers.Contract(tournamentContractAddress, tournamentContractABI, _signer);
    setProvider(_provider);
    setSigner(_signer);
    setContract(_contract);
  };

  const assignOrganizerRoleToUser = async (_address: string) => {
    const result = await contract.assignOrganizerRoleToUser(_address);
    console.log("assignOrganizerRoleToUser | result", result);
    return result;
  };
  const createUser = async (_username: string) => {
    const result = await contract.createUser(_username);
    console.log("createUser | result", result);
    return result;
  };
  const getUser = async (_userAddress: string) => {
    const result = await contract.getUser(_userAddress);
    console.log("getUser | result", result);
  };
  const createTournament = async (_name: string) => {
    const result = await contract.createTournament(_name, 0, 100, 2, [80, 20]);
    console.log("createTournament | result", result);
  };
  const getTournament = async (_id: string) => {
    const result = await contract.getTournament(_id);
    console.log("getTournament | result", result);
  };
  const joinTournament = async (_id: string) => {
    const result = await contract.joinTournament(_id, userAddress);
    console.log("joinTournament | result", result);
  };
  const startTournament = async (_id: string) => {
    const result = await contract.startTournament(_id);
    console.log("startTournament | result", result);
  };
  const completeTournament = async (_id: string) => {
    const result = await contract.completeTournament(_id, ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "0x90F79bf6EB2c4f870365E785982E1f101E93b906"]);
    console.log("startTournament | result", result);
  };
  const donateToTournament = async (_id: string) => {
    const txData = {
      value: ethers.utils.parseEther("12"),
    };
    const result = await contract.donateToTournament(_id, txData);
    console.log("donateToTournament | result", result);
  };
  const getTournamentBalance = async (_id: string) => {
    const result = await contract.getTournamentBalance(_id);
    console.log("getTournamentBalance | result", ethers.utils.formatEther(result));
  };
  const sendPaymentsToWinners = async (_id: string) => {
    const result = await contract.sendPaymentsToWinners(_id);
    console.log("sendPaymentsToWinners | result", result);
  };

  return (
    <>
      <div>
        <input
          placeholder="username"
          value={username}
          onChange={(e) => {
            setUsername(e.target.value);
          }}
        />
      </div>
      <div>
        <input
          placeholder="userAddress"
          value={userAddress}
          onChange={(e) => {
            setUserAddress(e.target.value);
          }}
        />
      </div>
      <div>
        <input
          placeholder="tournament name"
          value={tournamentName}
          onChange={(e) => {
            setTournamentName(e.target.value);
          }}
        />
      </div>
      <div>
        <input
          placeholder="tournamentId"
          value={tournamentId}
          onChange={(e) => {
            setTournamentId(e.target.value);
          }}
        />
      </div>
      <div>
        <input
          placeholder="donation"
          value={donationAmount}
          onChange={(e) => {
            setDonationAmount(e.target.value);
          }}
        />
      </div>
      <div>
        <button
          onClick={() => {
            connectToMetamask();
          }}
        >
          Connect To Metamask
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            setBlockchainTools();
          }}
        >
          Connect To Blockchain
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            assignOrganizerRoleToUser(userAddress);
          }}
        >
          Assign Role
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            createUser(username);
          }}
        >
          create user
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            getUser(userAddress);
          }}
        >
          get user
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            createTournament(tournamentName);
          }}
        >
          create tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            getTournament(tournamentId);
          }}
        >
          get tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            joinTournament(tournamentId);
          }}
        >
          join tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            startTournament(tournamentId);
          }}
        >
          start tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            completeTournament(tournamentId);
          }}
        >
          complete tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            donateToTournament(tournamentId);
          }}
        >
          donate tournament
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            getTournamentBalance(tournamentId);
          }}
        >
          tournament balance
        </button>
      </div>
      <div>
        <button
          onClick={() => {
            sendPaymentsToWinners(tournamentId);
          }}
        >
          send payments to winners
        </button>
      </div>
    </>
  );
}
