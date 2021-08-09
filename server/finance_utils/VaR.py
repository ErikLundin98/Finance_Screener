import numpy as np

def historical_simulation_relative_VaR(returns, window: int, prctile=95):
    returns = np.array(returns)
    VaR = np.zeros(returns.shape[0]-window)
    for i in range(VaR.shape[0]):
        distribution = returns[i:i+window]
        VaR[i] = np.percentile(distribution, prctile)

    return VaR


if __name__ == '__main__':
    returns = [0.02, 0.03, 0.02, 0.04, 0.05, 0.01, 0.023]
    print(historical_simulation_relative_VaR(returns, 2, 95))