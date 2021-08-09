import numpy as np

def equal_weighted_moving_average_vols(log_returns: np.ndarray, window: int = 30):
    n_observations = log_returns.shape[0]
    n_assets = log_returns.shape[1]
    vols = np.zeros((n_observations-(window-1), n_assets))

    for i in range(vols.shape[0]):
        vols[i,:] = np.sqrt(1/window * np.sum(log_returns[i:i+window-1,:], axis=0)^2 )
    
    return vols

def GARCH_1_1_vols(log_returns: np.ndarray, omega:float, alpha:float, beta:float):
    n_observations = log_returns.shape[0]
    n_assets = log_returns.shape[1]
    variances = np.zeros((n_observations, n_assets))
    variances[0,:] = log_returns[0,:]^2

    for i in range(1,n_observations):
        variances[i,:] = omega + alpha*log_returns[i-1,:]^2 + beta*variances[i-1,:]

    return np.sqrt(variances)

